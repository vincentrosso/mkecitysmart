const admin = require('firebase-admin');
const fetch = global.fetch || require('node-fetch');

// Initialize admin SDK (emulator env vars will be set by emulators:exec)
admin.initializeApp();

const db = admin.firestore();

async function main() {
  try {
    // Create a fresh user in the Auth emulator
    const user = await admin.auth().createUser({});
    const uid = user.uid;
    console.log('Created user uid=', uid);

    // Create a custom token for the user
    const customToken = await admin.auth().createCustomToken(uid);

    // Exchange the custom token for an ID token via the Auth emulator REST endpoint
    const exchangeUrl = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake';
    const exchResp = await fetch(exchangeUrl, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({token: customToken, returnSecureToken: true}),
    });
    const exchJson = await exchResp.json();
    if (!exchJson.idToken) throw new Error('Failed to exchange custom token: ' + JSON.stringify(exchJson));
    const idToken = exchJson.idToken;
    const localId = exchJson.localId || uid;
    console.log('Obtained idToken for localId=', localId);

    // Call the callable with Authorization header
    const funcUrl = 'http://127.0.0.1:5001/mkeparkapp-1ad15/us-central1/sendNearbyAlerts';
    const callResp = await fetch(funcUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + idToken,
      },
      body: JSON.stringify({data: {testMode: true, token: 'testtoken_auth_01234567890123456789', reason: 'E2E auth test from emulator'}}),
    });
    const callJson = await callResp.json();
    console.log('Function response:', JSON.stringify(callJson));

    // Read the rate-limit doc for this uid
    const rateDocId = `uid_${localId}`;
    const rateSnap = await db.collection('test_push_rate_limits').doc(rateDocId).get();
    if (!rateSnap.exists) {
      console.log('Rate doc not found for', rateDocId);
    } else {
      console.log('Rate doc data:', JSON.stringify(rateSnap.data(), null, 2));
    }

    // Read recent audit entries for this requester
    const auditSnap = await db.collection('test_push_audit').where('requester','==', localId).orderBy('createdAtMillis','desc').limit(5).get();
    if (auditSnap.empty) {
      console.log('No audit entries for requester', localId);
    } else {
      console.log('Recent audit entries:');
      auditSnap.docs.forEach((d) => {
        const data = d.data();
        console.log(`- id=${d.id} sent=${data.sent ?? 0} total=${data.total ?? 0} skipped=${data.skippedSends ? 'yes' : 'no'} reason=${(data.reason||'').slice(0,80)}`);
      });
    }
  } catch (err) {
    console.error('E2E error:', err);
    process.exitCode = 2;
  }
}

main();
