/**
 * Backfill missing displayName on user documents.
 * Derives name from email local-part (e.g. moussa.ndiaye@... → "Moussa Ndiaye").
 * Idempotent — skips docs that already have a displayName.
 *
 * Run: node scripts/fix-users-displayname.js
 */
const admin = require('../functions/node_modules/firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(require('./service-account.json')),
});

const db = admin.firestore();

function nameFromEmail(email) {
  const local = email.split('@')[0]; // e.g. "moussa.ndiaye"
  return local
    .split(/[._-]/)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

async function main() {
  const snap = await db.collection('users').get();
  let fixed = 0;
  let skipped = 0;

  const batch = db.batch();
  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.displayName) {
      console.log(`  ✓ ${data.email} — already has displayName, skipping`);
      skipped++;
      continue;
    }
    const name = nameFromEmail(data.email ?? doc.id);
    batch.update(doc.ref, { displayName: name });
    console.log(`  ✅ ${data.email} → displayName: "${name}"`);
    fixed++;
  }

  await batch.commit();
  console.log(`\nDone. Fixed: ${fixed}, Skipped: ${skipped}`);
}

main().catch((err) => {
  console.error('❌', err.message);
  process.exit(1);
});
