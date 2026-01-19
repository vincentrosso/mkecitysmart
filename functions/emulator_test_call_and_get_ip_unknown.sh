#!/bin/bash
set -euo pipefail

# Call the sendNearbyAlerts callable in testMode
curl -s -X POST "http://127.0.0.1:5001/mkeparkapp-1ad15/us-central1/sendNearbyAlerts" \
  -H "Content-Type: application/json" \
  -d '{"data":{"testMode":true,"token":"testtoken01234567890123456789","reason":"Integration test push from emulator"}}' \
  -w '\nHTTP_STATUS:%{http_code}\n'

echo
echo "---- Firestore: get test_push_rate_limits/ip_unknown ----"
echo "(Now reading the doc via admin SDK to bypass emulator security rules)"
node ./functions/read_rate_limit_admin.js || true
