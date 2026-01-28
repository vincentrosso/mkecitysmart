/*
 * Emulator smoke test for local development.
 *
 * What it does:
 *  - Calls helloWorld HTTP function (no auth)
 *  - Calls submitSighting without auth (expected unauthenticated OR rate limit behavior depending on implementation)
 *
 * NOTE: Admin-only callables (simulateNearbyWarning/testPushToSelf) require Firebase Auth tokens with custom claims,
 * which is outside the scope of this lightweight script.
 */

const http = require('http');

const PROJECT_ID = process.env.PROJECT_ID || 'mkeparkapp-1ad15';
const REGION = process.env.REGION || 'us-central1';
const FUNCTIONS_HOST = process.env.FUNCTIONS_HOST || '127.0.0.1';
const FUNCTIONS_PORT = Number(process.env.FUNCTIONS_PORT || 5001);

function postJson(path, body) {
  const payload = Buffer.from(JSON.stringify(body));

  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        host: FUNCTIONS_HOST,
        port: FUNCTIONS_PORT,
        path,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': payload.length,
        },
      },
      (res) => {
        const chunks = [];
        res.on('data', (d) => chunks.push(d));
        res.on('end', () => {
          const text = Buffer.concat(chunks).toString('utf8');
          resolve({ status: res.statusCode, text });
        });
      }
    );

    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

async function main() {
  const helloPath = `/${PROJECT_ID}/${REGION}/helloWorld`;
  const submitPath = `/${PROJECT_ID}/${REGION}/submitSighting`;

  // helloWorld is an onRequest; GET is typical, but we'll POST to keep one helper.
  const hello = await postJson(helloPath, {});
  console.log('helloWorld:', hello.status, hello.text.trim());

  const sighting = await postJson(submitPath, {
    data: {
      location: 'Emulator Test Location',
      notes: 'Emulator test report',
      isEnforcer: false,
      latitude: 43.0389,
      longitude: -87.9065,
      radiusMiles: 5,
    },
  });

  console.log('submitSighting:', sighting.status, sighting.text.trim());
}

main().catch((e) => {
  console.error('Smoke test failed:', e);
  process.exit(1);
});
