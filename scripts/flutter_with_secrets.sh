#!/usr/bin/env bash
set -euo pipefail

# Runs a Flutter command after ensuring Firebase secrets are available.
# Usage:
#   ./scripts/flutter_with_secrets.sh build apk --release
# or set FIREBASE_ENV_FILE=/path/to/env before running.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${FIREBASE_ENV_FILE:-"$ROOT_DIR/.env.firebase"}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing Firebase env file: $ENV_FILE" >&2
  echo "Copy .env.firebase.example to $ENV_FILE and fill in your secrets." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

copy_secret_file() {
  local src="$1"
  local dest="$2"
  local label="$3"
  if [[ -z "$src" ]]; then
    echo "[$label] Skipped (no path provided)." >&2
    return
  fi
  if [[ ! -f "$src" ]]; then
    echo "[$label] Secret file not found at $src" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "[$label] Copied into $(realpath "$dest")"
}

copy_secret_file "${FIREBASE_ANDROID_GOOGLE_SERVICES_PATH:-}" \
  "$ROOT_DIR/android/app/google-services.json" \
  "android/google-services.json"
copy_secret_file "${FIREBASE_IOS_GOOGLE_SERVICE_INFO_PATH:-}" \
  "$ROOT_DIR/ios/Runner/GoogleService-Info.plist" \
  "ios/GoogleService-Info.plist"
copy_secret_file "${FIREBASE_MACOS_GOOGLE_SERVICE_INFO_PATH:-}" \
  "$ROOT_DIR/macos/Runner/GoogleService-Info.plist" \
  "macos/GoogleService-Info.plist"

declare -a dart_defines=()
add_define() {
  local key="$1"
  local value="${!key:-}"
  if [[ -z "$value" ]]; then
    echo "[warn] Missing dart-define for $key" >&2
  else
    dart_defines+=("--dart-define=$key=$value")
  fi
}

firebase_define_keys=(
  FIREBASE_WEB_API_KEY
  FIREBASE_WEB_APP_ID
  FIREBASE_WEB_MESSAGING_SENDER_ID
  FIREBASE_WEB_PROJECT_ID
  FIREBASE_WEB_AUTH_DOMAIN
  FIREBASE_WEB_STORAGE_BUCKET
  FIREBASE_WEB_MEASUREMENT_ID
  FIREBASE_ANDROID_API_KEY
  FIREBASE_ANDROID_APP_ID
  FIREBASE_ANDROID_MESSAGING_SENDER_ID
  FIREBASE_ANDROID_PROJECT_ID
  FIREBASE_ANDROID_STORAGE_BUCKET
  FIREBASE_IOS_API_KEY
  FIREBASE_IOS_APP_ID
  FIREBASE_IOS_MESSAGING_SENDER_ID
  FIREBASE_IOS_PROJECT_ID
  FIREBASE_IOS_STORAGE_BUCKET
  FIREBASE_IOS_BUNDLE_ID
)

for key in "${firebase_define_keys[@]}"; do
  add_define "$key"
done

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <flutter args...>" >&2
  exit 1
fi

first_arg="${1:-}"
if [[ "$first_arg" == "pub" || "$first_arg" == "packages" ]]; then
  # pub commands do not accept --dart-define flags.
  echo "Running (no dart-define flags needed): flutter $*"
  flutter "$@"
else
  joined_defines="${dart_defines[*]-}"
  echo "Running: flutter $* $joined_defines"
  if [[ ${#dart_defines[@]} -eq 0 ]]; then
    flutter "$@"
  else
    flutter "$@" "${dart_defines[@]}"
  fi
fi
