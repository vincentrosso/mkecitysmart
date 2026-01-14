# MKEPark Flutter

CitySmart’s MKEPark experience is a cross-platform Flutter app focused on
parking insights, ticket reminders, and municipal workflows for Milwaukee
drivers. This repository contains:

- The Flutter client (Android, iOS, web, desktop stubs).
- Backend scaffolding (FastAPI stub under `backend/`) used for development.
- Tooling to manage Firebase secrets, CI builds, and automated versioning.

## Highlights
- 🚗 Real-time parking risk indicators, permit workflows, and reporting flows.
- 🔔 Firebase Cloud Messaging integration for alerts and local notifications.
- 🔒 Secrets-managed builds via `scripts/flutter_with_secrets.sh` so no Firebase
  credentials live in git.
- 🧪 GitHub Actions pipelines for Android/iOS builds (`mobile_build.yml`).
- 🔁 Automatic pubspec version bumps on commits to `main`
  (`.github/workflows/auto_version.yml`).

## Requirements
- Flutter `3.35.7` (or whichever version you pin in `env.FLUTTER_VERSION`).
- Dart SDK ≥ `3.9.2`.
- Xcode `16.1` (for iOS builds) with the iOS 18.1 platform installed.
- Android SDK + NDK 27, CMake 3.22, Java 17 toolchain.
- Firebase CLI (for App Distribution/beta deployments).

## Local Setup
1. Install Flutter and ensure `flutter doctor` passes for your target platforms.
2. Copy secrets template and fill in real values (Firebase + App Store Connect):
   ```bash
   cp .env.firebase.example .env.firebase
   # edit and point to secure google-services.json / GoogleService-Info.plist files
   ```
3. Run Flutter commands through the helper script so configs are injected:
   ```bash
   ./scripts/flutter_with_secrets.sh pub get
   ./scripts/flutter_with_secrets.sh run -d ios
   ./scripts/flutter_with_secrets.sh build apk --release
   ```
4. Use VS Code/Android Studio normally once the native config files are copied.
5. Run the doctor to verify Flutter + secrets are wired up:
   ```bash
   python scripts/doctor.py
   ```

## Local Secrets Layout
- `.env.firebase` – copy from the example and fill in every `FIREBASE_*` plus the
  App Store Connect values (`APP_STORE_CONNECT_API_KEY_ID`,
  `APP_STORE_CONNECT_API_ISSUER`). Request the real values from the CitySmart
  release manager and paste them into this file; it never leaves your machine.
- `.secrets/firebase/android/google-services.json` /
  `.secrets/firebase/ios/GoogleService-Info.plist` /
  `.secrets/firebase/macos/GoogleService-Info.plist` – download the official
  Firebase configs (again provided via the secure secrets bundle) and drop them
  into these exact paths. `scripts/flutter_with_secrets.sh` and
  `scripts/doctor.py` both look here automatically.
- `.secrets/apple/…` – store signing assets like
  `codemagic_code_sign.p12`, `J8U8FW3PA8_*.mobileprovision`, and any App Store
  Connect API keys used by Codemagic. Use `scripts/codemagic_sync.py` to push
  these to Codemagic groups when needed.
- `web/firebase-config.json` – for Flutter web builds, copy
  `web/firebase-config.example.json` to `web/firebase-config.json` and paste in
  the Firebase Web SDK values (API key, project ID, etc.). This file is
  git-ignored but read at runtime so you don’t need dart defines for the web
  target.
- `~/.private_keys/AuthKey_<KEYID>.p8` – Apple requires App Store Connect API
  keys for `xcrun altool` builds to live in one of their default directories.
  Keep the `.p8` file out of the repo (the git-ignored `private_keys/` folder is
  available as a staging area) and copy it into `~/.private_keys/` so
  `scripts/ios_build_and_upload.sh` can upload successfully.
- Whenever you refresh secrets or change machines, re-run
  `python scripts/doctor.py` to confirm nothing drifted.

## Firebase Secrets & CI
- Sensitive files (`android/app/google-services.json`,
  `ios/Runner/GoogleService-Info.plist`, etc.) live outside git in `.secrets/`.
- `.env.firebase` stores all `--dart-define` values and file paths. It is
  git-ignored; share via secure channels only.
- `docs/SECRETS.md` describes how to encode these secrets for GitHub Actions.
- GitHub secrets expected by `mobile_build.yml`:
  - `FIREBASE_ENV_FILE` – entire `.env.firebase`.
  - `ANDROID_GOOGLE_SERVICES_JSON` – base64 of `google-services.json`.
- `IOS_GOOGLE_SERVICE_INFO_PLIST` – base64 of `GoogleService-Info.plist`.

## Cloud Logging
- Firestore is used for lightweight cloud logging. `lib/services/cloud_log_service.dart`
  initializes once Firebase is ready and writes events to the `appLogs` collection
  (each entry includes an `event` name, metadata, and timestamp).
- Enable Firestore for your Firebase project and grant the app write access to
  `appLogs` (e.g., via environment-specific security rules).
- Common events include app bootstrap, tab changes, sightings, auth actions, and
  push-notification lifecycle events, giving you a basic timeline of user
  behavior without shipping full analytics SDKs.

## Codemagic CI/CD
- GitHub Actions workflows are paused (only manual `workflow_dispatch`) because
  Codemagic now handles builds/releases. Use `.github/workflows/...` manually
  if needed.
- `codemagic.yaml` defines two workflows:
  - `ios_release`: builds with Xcode 16.2, signs using the env vars
    `IOS_DISTRIBUTION_CERTIFICATE`, `IOS_CERTIFICATE_PASSWORD`,
    `IOS_PROVISIONING_PROFILE`, and publishes to the App Store via
    `APP_STORE_CONNECT_*` variables.
  - `android_release`: restores Firebase secrets, optionally decodes an Android
    keystore (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`,
    `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`), and produces both AAB
    and APK artifacts.
- Recommended Codemagic variable groups:
  - `firebase-secrets`: `FIREBASE_ENV_FILE`,
    `ANDROID_GOOGLE_SERVICES_JSON`, `IOS_GOOGLE_SERVICE_INFO_PLIST`.
  - `ios-signing`: `IOS_DISTRIBUTION_CERTIFICATE`,
    `IOS_CERTIFICATE_PASSWORD`, `IOS_PROVISIONING_PROFILE`.
  - `app-store-connect`: `APP_STORE_CONNECT_APPLE_ID`,
    `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_IDENTIFIER`,
    `APP_STORE_CONNECT_PRIVATE_KEY`, `APP_STORE_CONNECT_APP_ID`.
  - `android-signing` (optional): `ANDROID_KEYSTORE_BASE64`,
    `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
- Copy `codemagic.conf` (git-ignored) from the repo root and populate it with
  your Codemagic app ID, API token, and local file paths (defaults already point
  to `.env.firebase`, `.secrets/firebase/...`, and `.secrets/apple/...`). Then
  you can run the sync script without flags. Examples:
  ```bash
  python scripts/codemagic_sync.py --group firebase-secrets
  python scripts/codemagic_sync.py --group ios-signing
  python scripts/codemagic_sync.py --group app-store-connect
  ```
- If you prefer passing flags manually, here are equivalent commands:
  - Firebase secrets (`firebase-secrets`):
  ```bash
  python scripts/codemagic_sync.py --group firebase-secrets \
    --env-file .env.firebase \
    --android-json .secrets/firebase/android/google-services.json \
    --ios-plist .secrets/firebase/ios/GoogleService-Info.plist
  ```
  - Signing assets (`ios-signing`):
  ```bash
  python scripts/codemagic_sync.py --group ios-signing \
    --distribution-p12 .secrets/apple/codemagic_code_sign.p12 \
    --distribution-p12-password '<p12 password>' \
    --provisioning-profile .secrets/apple/J8U8FW3PA8_20251204.mobileprovision
  ```
  - App Store Connect API key (`app-store-connect`):
  ```bash
  python scripts/codemagic_sync.py --group app-store-connect \
    --app-store-key .secrets/apple/Codemagic_AppStoreConnectApi_AuthKey_<KEYID>.p8
  ```

## Automated Versioning
- Every push to `main` triggers `.github/workflows/auto_version.yml`.
- `scripts/bump_version.py` increments the `pubspec.yaml` version line
  (patch + build number) and commits back using the GitHub Actions bot.
- Skip the bump by adding `[skip version]` to your commit message or pushing
  from a branch other than `main`.
- Manual bumps remain possible—just edit `pubspec.yaml` before merging.

## CI/CD Overview
- **`mobile_build.yml`**  
  Builds Android release APKs (Ubuntu runners) and iOS unsigned IPAs (macOS 15
  runners + Xcode 16.1). Artifacts are uploaded for download/testing.
- **`auto_version.yml`**  
  Runs immediately after merges to `main` so the repo always has a fresh build
  number.
- Extend either workflow with Fastlane or Firebase App Distribution to push QA
  builds. Add steps after the build stage:
  ```bash
  firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
    --app <ANDROID_FIREBASE_APP_ID> --groups beta --release-notes "Build $GITHUB_RUN_NUMBER"
  ```

## Useful Scripts
- `scripts/flutter_with_secrets.sh` – wraps any `flutter` command, copies secret
  config files, and forwards all Firebase dart-defines.
- `scripts/bump_version.py` – increments the `pubspec.yaml` version string.
- `scripts/create_citysmart_bundle.sh` – exports assets for marketing demos.
- `scripts/doctor.py` – sanity-checks Flutter installs and required Firebase
  secrets (env vars + `GoogleService-Info.plist` paths).
- `scripts/ios_build_and_upload.sh` – bumps the `pubspec.yaml` version + `CFBundleVersion`, runs
  `flutter build ipa -v --release`, and uploads the resulting IPA with `xcrun altool`
  using `APP_STORE_CONNECT_*` values sourced from `.env.firebase` (override via env vars as needed).

## Project Structure
- `lib/` – Flutter code organized by screens, services, providers, theme.
- `backend/` – FastAPI health check stub for local integration tests.
- `docs/` – Integration + secrets documentation.
- `.github/workflows/` – CI definitions (build + auto versioning).

## Next Steps / Deployment
- Configure Firebase App Distribution (or Fastlane) for Android/iOS to send
  builds to testers.
- Add signing credentials to GitHub secrets if you plan to upload automatically
  to Google Play/App Store.
- Wire the `backend/` API routes to live services for parking predictions,
  device registration, and reporting.
- For App Store uploads, confirm export compliance by answering Apple's prompt or by
  relying on `ITSAppUsesNonExemptEncryption=false` in `ios/Runner/Info.plist` if you do
  not ship custom encryption.

Happy building! 🚀
