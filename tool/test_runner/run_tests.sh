#!/usr/bin/env bash
set -euo pipefail

# Lightweight local/CI test runner with coverage enforcement.
# Usage: ./tool/test_runner/run_tests.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"

echo "==> Installing deps"
(
  cd "$ROOT_DIR"
  "$FLUTTER_BIN" pub get
)

echo "==> Running unit tests with coverage (SKIP_FIREBASE)"
(
  cd "$ROOT_DIR"
  SKIP_FIREBASE=true ENABLE_PUSH_NOTIFICATIONS=false \
    "$FLUTTER_BIN" test \
    --coverage \
    test/unit \
    --dart-define=SKIP_FIREBASE=true \
    --dart-define=ENABLE_PUSH_NOTIFICATIONS=false
)

echo "==> Running widget/smoke tests (no coverage)"
(
  cd "$ROOT_DIR"
  SKIP_FIREBASE=true ENABLE_PUSH_NOTIFICATIONS=false \
    "$FLUTTER_BIN" test \
    test/widget \
    --dart-define=SKIP_FIREBASE=true \
    --dart-define=ENABLE_PUSH_NOTIFICATIONS=false
)

echo "==> Checking coverage >= ${COVERAGE_THRESHOLD}%"
python3 "$ROOT_DIR/tool/test_runner/verify_coverage.py" \
  --threshold "$COVERAGE_THRESHOLD" \
  --lcov "$ROOT_DIR/coverage/lcov.info" \
  --include lib/models \
  --include lib/services/alternate_side_parking_service.dart \
  --include lib/services/city_ticket_stats_service.dart \
  --include lib/services/ticket_risk_prediction_service.dart \
  --include lib/services/parking_prediction_service.dart \
  --include lib/services/open_charge_map_service.dart \
  --include lib/services/weather_service.dart \
  --include lib/services/garbage_schedule_service.dart \
  --include lib/services/ticket_lookup_service.dart \
  --include lib/services/bootstrap_diagnostics.dart \
  --include lib/services/user_repository.dart \
  --include lib/models

echo "✅ Tests + coverage check complete."
