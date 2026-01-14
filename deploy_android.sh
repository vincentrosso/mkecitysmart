#!/bin/bash

# ===============================
# FLUTTER ANDROID DEPLOY SCRIPT
# ===============================
# This script:
#   1. Increments the Flutter versionCode in pubspec.yaml
#   2. Builds a release Android App Bundle (.aab)
#   3. Uploads the bundle to Google Play using Fastlane Supply
#
# Requirements:
#   * Flutter SDK
#   * Fastlane (install via `sudo gem install fastlane -NV` if missing)
#   * Google Play service account JSON at android/play-account.json

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# --------- CONFIG: EDIT THESE ---------
APP_NAME="mkecitysmart"
PACKAGE_NAME="com.mkecitysmart.app"   # Update to the final app id if different
SERVICE_ACCOUNT_JSON="/Users/vincentrosso/Dropbox/development/codex/mkecitysmart-6edc3-3befbcafc8aa.json"
FASTLANE_DIR="android/fastlane"
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
PUBSPEC="pubspec.yaml"
# Precompute absolute path to avoid Fastlane cwd issues.
AAB_ABSOLUTE_PATH="$ROOT_DIR/$AAB_PATH"
# Normalize service account path to absolute.
if [[ "$SERVICE_ACCOUNT_JSON" = /* ]]; then
  SERVICE_ACCOUNT_ABSOLUTE_PATH="$SERVICE_ACCOUNT_JSON"
else
  SERVICE_ACCOUNT_ABSOLUTE_PATH="$ROOT_DIR/$SERVICE_ACCOUNT_JSON"
fi
# --------------------------------------

TRACK="${1:-internal}"          # internal | alpha | beta | production | custom track name
RELEASE_STATUS="${2:-draft}"    # draft | inProgress | completed | halted

echo "🤖 Deploying ${APP_NAME} (${PACKAGE_NAME}) to Google Play"

# ----------------------------
# Step 0: Validate prerequisites
# ----------------------------
if [ ! -f "$SERVICE_ACCOUNT_ABSOLUTE_PATH" ]; then
  cat <<EOF
❌ Google Play service account JSON not found at $SERVICE_ACCOUNT_JSON
   Download it from Google Play Console → Setup → API access and place it there.
EOF
  exit 1
fi

echo "🔧 Checking required tools..."
if ! command -v fastlane >/dev/null 2>&1; then
  echo "⚠️ Fastlane not found. Installing..."
  sudo gem install fastlane -NV
fi

for cmd in flutter python3 fastlane; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ Required tool '$cmd' is not available. Install it and retry."
    exit 1
  fi
done

# ----------------------------
# Step 1: Increment versionCode
# ----------------------------
if [ ! -f "$PUBSPEC" ]; then
  echo "❌ pubspec.yaml not found at $PUBSPEC"
  exit 1
fi

echo "🔢 Incrementing Android version code (pubspec.yaml)..."
VERSION_VARS="$(python3 <<'PY'
import pathlib
import re
import sys

path = pathlib.Path("pubspec.yaml")
text = path.read_text()
match = re.search(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?', text, re.MULTILINE)
if not match:
    sys.exit("pubspec.yaml does not contain a parsable version line (e.g. version: 1.2.3+4).")

base = match.group(1)
code = int(match.group(2) or 0)
new_code = code + 1

old = f"{base}+{code}"
new = f"{base}+{new_code}"

updated = text[:match.start()] + f"version: {base}+{new_code}" + text[match.end():]
path.write_text(updated)

print(f"OLD_VERSION='{old}'")
print(f"NEW_VERSION='{new}'")
PY
)"
eval "$VERSION_VARS"

echo "✅ Version updated: $OLD_VERSION → $NEW_VERSION"

# ----------------------------
# Step 2: Clean & build bundle
# ----------------------------
echo "🧹 Cleaning Flutter build..."
flutter clean

echo "📦 Building Android App Bundle (release)..."
flutter build appbundle --release

if [ ! -f "$AAB_ABSOLUTE_PATH" ]; then
  echo "❌ Build failed: AAB not found at $AAB_PATH"
  exit 1
fi

# ----------------------------
# Step 3: Prepare Fastlane files
# ----------------------------
mkdir -p "$FASTLANE_DIR"

cat > "$FASTLANE_DIR/Appfile" <<EOF
json_key_file("$SERVICE_ACCOUNT_ABSOLUTE_PATH")
package_name("$PACKAGE_NAME")
EOF

cat > "$FASTLANE_DIR/Fastfile" <<'EOF'
default_platform(:android)

platform :android do
  desc "Upload Flutter bundle to Google Play"
  lane :release do
    track = ENV.fetch("PLAY_TRACK", "internal")
    status = ENV.fetch("PLAY_RELEASE_STATUS", "draft")
    aab_path = ENV.fetch("PLAY_AAB_PATH", "../build/app/outputs/bundle/release/app-release.aab")

    unless File.exist?(aab_path)
      UI.user_error!("AAB not found at #{aab_path}")
    end

    supply(
      track: track,
      release_status: status,
      aab: aab_path,
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
end
EOF

# ----------------------------
# Step 4: Upload via Fastlane
# ----------------------------
echo "🚀 Uploading bundle to Google Play (track=$TRACK, status=$RELEASE_STATUS)..."
pushd android >/dev/null
export PLAY_TRACK="$TRACK"
export PLAY_RELEASE_STATUS="$RELEASE_STATUS"
export PLAY_AAB_PATH="$AAB_ABSOLUTE_PATH"
fastlane release
popd >/dev/null

# ----------------------------
# Step 5: Done!
# ----------------------------
echo "✅ Deployment complete!"
echo "   Version: $NEW_VERSION"
echo "   Track: $TRACK (status: $RELEASE_STATUS)"
echo "   Google Play Console → https://play.google.com/console"
