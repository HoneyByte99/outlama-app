/**
 * Migration: backfill customerId + providerId on existing chat documents.
 * Looks up each chat's linked booking to get the correct values.
 * Safe to run multiple times (idempotent).
 */
const admin = require('../functions/node_modules/firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(require('./service-account.json')),
});

const db = admin.firestore();

async function main() {
  const chatsSnap = await db.collection('chats').get();

  if (chatsSnap.empty) {
    console.log('No chat documents found.');
    return;
  }

  let fixed = 0;
  let skipped = 0;

  for (const chatDoc of chatsSnap.docs) {
    const chat = chatDoc.data();

    // Already migrated
    if (chat.customerId && chat.providerId) {
      console.log(`  ✓ ${chatDoc.id} — already has roles, skipping`);
      skipped++;
      continue;
    }

    const bookingId = chat.bookingId;
    if (!bookingId) {
      console.warn(`  ⚠ ${chatDoc.id} — no bookingId, skipping`);
      skipped++;
      continue;
    }

    const bookingSnap = await db.collection('bookings').doc(bookingId).get();
    if (!bookingSnap.exists) {
      console.warn(`  ⚠ ${chatDoc.id} — booking ${bookingId} not found, skipping`);
      skipped++;
      continue;
    }

    const booking = bookingSnap.data();
    const { customerId, providerId } = booking;

    if (!customerId || !providerId) {
      console.warn(`  ⚠ ${chatDoc.id} — booking missing customerId/providerId, skipping`);
      skipped++;
      continue;
    }

    await chatDoc.ref.update({ customerId, providerId });
    console.log(`  ✅ ${chatDoc.id} — set customerId=${customerId} providerId=${providerId}`);
    fixed++;
  }

  console.log(`\nDone. Fixed: ${fixed}, Skipped: ${skipped}`);
}

main().catch((err) => {
  console.error('❌', err.message);
  process.exit(1);
});
