#!/bin/bash
set -euo pipefail

echo "Signing in anonymously against Auth emulator..."
resp=$(curl -s -X POST "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake_api_key" \
  -H "Content-Type: application/json" \
  -d '{"returnSecureToken":true}')

idToken=$(python3 - <<PY
import sys, json
o = json.load(sys.stdin)
print(o.get('idToken',''))
PY
<<<"$resp")

uid=$(python3 - <<PY
import sys, json
o = json.load(sys.stdin)
print(o.get('localId',''))
PY
<<<"$resp")

if [ -z "$idToken" ]; then
  echo "Failed to sign in anonymously; response:" >&2
  echo "$resp" >&2
  exit 2
fi

echo "Signed in: uid=$uid"

echo
echo "Calling sendNearbyAlerts callable with Authorization header..."
curl -s -X POST "http://127.0.0.1:5001/mkeparkapp-1ad15/us-central1/sendNearbyAlerts" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${idToken}" \
  -d '{"data":{"testMode":true,"token":"testtoken01234567890123456789","reason":"E2E anon test push"}}' \
  -w '\nHTTP_STATUS:%{http_code}\n'

echo
echo "---- Firestore: read rate-limit doc for uid_${uid} ----"
node ./functions/read_rate_limit_for.js "uid_${uid}" || true

echo
echo "---- Recent audit entries ----"
node ./functions/read_rate_limit_admin.js || true
