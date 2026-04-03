/**
 * One-shot script: sets CORS on the Firebase Storage bucket.
 * Needed so Flutter Web can load avatar images via Image.network.
 * Run once: node scripts/set-storage-cors.js
 */
const { Storage } = require('../functions/node_modules/@google-cloud/storage');

const BUCKET = 'outalmaservice-d1e59.firebasestorage.app';

const CORS = [
  {
    origin: ['*'],
    method: ['GET', 'HEAD'],
    maxAgeSeconds: 3600,
    responseHeader: ['Content-Type', 'Content-Length', 'Content-Disposition'],
  },
];

async function main() {
  const storage = new Storage({
    keyFilename: './scripts/service-account.json',
  });

  const bucket = storage.bucket(BUCKET);
  await bucket.setCorsConfiguration(CORS);
  console.log(`✅ CORS set on gs://${BUCKET}`);

  const [metadata] = await bucket.getMetadata();
  console.log('Current CORS:', JSON.stringify(metadata.cors, null, 2));
}

main().catch((err) => {
  console.error('❌', err.message);
  process.exit(1);
});
