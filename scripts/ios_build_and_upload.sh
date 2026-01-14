#!/usr/bin/env bash
set -euo pipefail

# One-stop iOS release helper:
#   1. Increments CFBundleVersion in ios/Runner/Info.plist.
#   2. Runs `flutter build ipa -v --release`.
#   3. Renames the IPA to mkecitysmart.ipa (unless IPA_NAME is set).
#   4. Uploads to App Store Connect via `xcrun altool`.
#
# Requirements:
#   - Flutter and Xcode CLIs available (`flutter`, `xcrun`).
#   - App Store Connect API key installed under ~/.private_keys/AuthKey_<ID>.p8.
#   - API key + issuer stored in .env.firebase (or exported) as APP_STORE_CONNECT_API_KEY_ID / APP_STORE_CONNECT_API_ISSUER.
#
# Optional env vars:
#   FLUTTER_BIN – override flutter binary (default: flutter)
#   IPA_NAME – filename for build/ios/ipa/<name>.ipa (default: mkecitysmart.ipa)
#   APP_STORE_CONNECT_API_KEY_ID / APP_STORE_CONNECT_API_ISSUER – override values from .env.firebase if needed.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC="$ROOT_DIR/pubspec.yaml"
INFO_PLIST="$ROOT_DIR/ios/Runner/Info.plist"
IPA_DIR="$ROOT_DIR/build/ios/ipa"
IPA_NAME="${IPA_NAME:-mkecitysmart.ipa}"
IPA_PATH="$IPA_DIR/$IPA_NAME"
PLIST_BUDDY="/usr/libexec/PlistBuddy"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
ENV_FILE="${IOS_DEPLOY_ENV_FILE:-$ROOT_DIR/.env.firebase}"

log() {
  printf "\n[%s] %s\n" "$(date '+%H:%M:%S')" "$*"
}

if [[ -f "$ENV_FILE" ]]; then
  log "Loading deploy env from $ENV_FILE"
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
else
  log "No env file at $ENV_FILE (set IOS_DEPLOY_ENV_FILE to override)."
fi

API_KEY_ID="${APP_STORE_CONNECT_API_KEY_ID:-}"
API_ISSUER="${APP_STORE_CONNECT_API_ISSUER:-}"

require_file() {
  local path="$1"
  local label="$2"
  if [[ ! -f "$path" ]]; then
    echo "❌ Missing ${label}: $path" >&2
    exit 1
  fi
}

bump_pubspec_version() {
  require_file "$PUBSPEC" "pubspec.yaml"
  require_file "$ROOT_DIR/scripts/bump_version.py" "scripts/bump_version.py"
  log "Bumping pubspec.yaml version/build"
  (cd "$ROOT_DIR" && python3 scripts/bump_version.py)
}

bump_build_number() {
  require_file "$INFO_PLIST" "Info.plist"
  local current=$($PLIST_BUDDY -c "Print CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "0")
  if ! [[ "$current" =~ ^[0-9]+$ ]]; then
    echo "⚠️  CFBundleVersion '$current' is not numeric. Resetting to 0."
    current=0
  fi
  local next=$((current + 1))
  $PLIST_BUDDY -c "Set :CFBundleVersion $next" "$INFO_PLIST"
  log "CFBundleVersion bumped: $current → $next"
}

build_flutter_ipa() {
  log "Starting flutter build ipa -v --release"
  (cd "$ROOT_DIR" && "$FLUTTER_BIN" build ipa -v --release)
  if [[ ! -d "$IPA_DIR" ]]; then
    echo "❌ Flutter build did not create $IPA_DIR" >&2
    exit 1
  fi
  local built_ipa=""
  if [[ -f "$IPA_DIR/Runner.ipa" ]]; then
    built_ipa="$IPA_DIR/Runner.ipa"
  else
    built_ipa="$(find "$IPA_DIR" -name '*.ipa' -maxdepth 1 | head -n 1 || true)"
  fi
  if [[ -z "$built_ipa" ]]; then
    echo "❌ No IPA found under $IPA_DIR" >&2
    exit 1
  fi
  if [[ "$built_ipa" != "$IPA_PATH" ]]; then
    log "Renaming $(basename "$built_ipa") → $(basename "$IPA_PATH")"
    mv -f "$built_ipa" "$IPA_PATH"
  fi
}

upload_with_altool() {
  require_file "$IPA_PATH" "IPA"
  log "Uploading $IPA_PATH to App Store Connect via altool"
  xcrun altool \
    --upload-app \
    --type ios \
    -f "$IPA_PATH" \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER"
  log "Upload finished."
}

if [[ -z "$API_KEY_ID" || -z "$API_ISSUER" ]]; then
  echo "❌ Set APP_STORE_CONNECT_API_KEY_ID and APP_STORE_CONNECT_API_ISSUER before running." >&2
  exit 1
fi

bump_pubspec_version
bump_build_number
build_flutter_ipa
upload_with_altool
