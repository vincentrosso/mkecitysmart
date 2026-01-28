#!/usr/bin/env node

/**
 * Production callable invoker for simulateNearbyWarning.
 *
 * This uses the Firebase client SDK invocation style via direct HTTPS POST to the
 * callable endpoint URL.
 *
 * Auth: expects you to supply a Firebase Auth ID token for a user that is
 * admin/mod in your backend (since simulateNearbyWarning is admin/mod only).
 *
 * Usage:
 *   node tools/prod_call_simulate_nearby_warning.js \
 *     --project mkeparkapp-1ad15 \
 *     --region us-central1 \
 *     --id-token "<FIREBASE_ID_TOKEN>" \
 *     --lat 43.0389 --lng -87.9065 --radius-miles 5
 */

const https = require('https');

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith('--')) continue;
    const key = a.slice(2);
    const next = argv[i + 1];
    if (next && !next.startsWith('--')) {
      args[key] = next;
      i++;
    } else {
      args[key] = true;
    }
  }
  return args;
}

function postJson(url, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const req = https.request(
      {
        method: 'POST',
        hostname: u.hostname,
        path: u.pathname + u.search,
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
          ...headers,
        },
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => resolve({ status: res.statusCode, body: data }));
      }
    );
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function main() {
  const args = parseArgs(process.argv);

  const project = args.project || process.env.FIREBASE_PROJECT || 'mkeparkapp-1ad15';
  const region = args.region || 'us-central1';
  const idToken = args['id-token'] || process.env.FIREBASE_ID_TOKEN;

  if (!idToken) {
    console.error('Missing --id-token (or env FIREBASE_ID_TOKEN).');
    process.exit(2);
  }

  const lat = Number(args.lat);
  const lng = Number(args.lng);
  const radiusMiles = args['radius-miles'] ? Number(args['radius-miles']) : undefined;

  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    console.error('Missing/invalid --lat and --lng');
    process.exit(2);
  }

  const url = `https://${region}-${project}.cloudfunctions.net/simulateNearbyWarning`;
  const payload = {
    data: {
      latitude: lat,
      longitude: lng,
      radiusMiles,
    },
  };

  const res = await postJson(url, JSON.stringify(payload), {
    Authorization: `Bearer ${idToken}`,
  });

  let parsed;
  try {
    parsed = JSON.parse(res.body);
  } catch {
    parsed = res.body;
  }

  console.log(JSON.stringify({ status: res.status, response: parsed }, null, 2));

  if (res.status >= 400) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
