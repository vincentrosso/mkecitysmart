const admin = require('firebase-admin');

// Initialize admin SDK (emulator env vars will be set by emulators:exec)
admin.initializeApp();

const db = admin.firestore();

async function main() {
  try {
    const docRef = db.collection('test_push_rate_limits').doc('ip_unknown');
    const snap = await docRef.get();
    if (!snap.exists) {
      console.log('Document not found: test_push_rate_limits/ip_unknown');
      return;
    }
    console.log('Document data:', JSON.stringify(snap.data(), null, 2));
    
    // Also list recent audit entries
    console.log('\nRecent test_push_audit entries:');
  const auditSnap = await db.collection('test_push_audit').orderBy('createdAtMillis', 'desc').limit(5).get();
    if (auditSnap.empty) {
      console.log('  (no audit entries)');
    } else {
      auditSnap.docs.forEach((d) => {
        const data = d.data();
        // show a summarized view
        console.log(`- id=${d.id} requester=${data.requester ?? 'null'} sent=${data.sent ?? 0} total=${data.total ?? 0} skipped=${data.skippedSends ? 'yes' : 'no'} reason=${(data.reason||'').slice(0,80)}`);
      });
    }
  } catch (err) {
    console.error('Error reading doc:', err);
    process.exitCode = 2;
  }
}

main();
