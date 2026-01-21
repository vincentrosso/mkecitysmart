const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

async function main() {
  const arg = process.argv[2];
  if (!arg) {
    console.error('Usage: node read_rate_limit_for.js <requesterId>');
    process.exitCode = 2;
    return;
  }
  try {
    const docRef = db.collection('test_push_rate_limits').doc(arg);
    const snap = await docRef.get();
    if (!snap.exists) {
      console.log(`Document not found: test_push_rate_limits/${arg}`);
      return;
    }
    console.log('Document data:', JSON.stringify(snap.data(), null, 2));
  } catch (err) {
    console.error('Error reading doc:', String(err));
    process.exitCode = 2;
  }
}

main();
