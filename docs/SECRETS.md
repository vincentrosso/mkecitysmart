# Secrets and Firebase Config Management

This repo should not contain any Firebase credentials, API keys, or
platform-specific config files.  Instead, secrets are supplied at build time
via a small wrapper script and a local env file.

## Files that must stay out of git

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`
- The actual Firebase option values for every platform

The `.gitignore` excludes these paths by default.  Your CI/CD pipeline (or your
local workstation) is responsible for copying them into place before running
`flutter build` / `flutter run`.

## Providing secrets locally

1. Copy `.env.firebase.example` to `.env.firebase` (which is git-ignored).
2. Fill in the full set of `FIREBASE_*` values plus the paths to the native
   Firebase config files that you downloaded from the Firebase console. The
   example file assumes you store them under `.secrets/firebase/<platform>/`
   so scripts and `python scripts/doctor.py` all look in one place. The same
   file now also holds App Store Connect values (`APP_STORE_CONNECT_API_KEY_ID`
   and `APP_STORE_CONNECT_API_ISSUER`) for the iOS upload helper. For Flutter
   web, copy `web/firebase-config.example.json` to `web/firebase-config.json`
   and paste the Firebase Web SDK values so the dev server can serve them
   without dart-defines.
3. Run Flutter commands through the wrapper script so secrets are injected,
   for example:

   ```bash
   ./scripts/flutter_with_secrets.sh build apk --release
   ./scripts/flutter_with_secrets.sh run -d ios
   ```

   The script will:
   - Copy `google-services.json` / `GoogleService-Info.plist` into the platform
     folders so plugins like `firebase_messaging` can find them.
   - Pass every `FIREBASE_*` value as a `--dart-define` so
     `lib/firebase_options.dart` receives the correct credentials at compile
     time.

4. Run the doctor to confirm everything is wired up before building:
   ```bash
   python scripts/doctor.py
   ```
5. CI/CD can use the same script by setting `FIREBASE_ENV_FILE` to point at an
   injected secret file or by exporting all the required variables before
   invoking the wrapper.

## Why not check config files into git?

Firebase config files usually contain API keys and identifiers that an attacker
could abuse to send push notifications or to call backend APIs.  Keeping them
out of git:

- prevents accidental leaks from forks or open-source mirroring,
- reduces blast radius if the repository is compromised,
- makes it easy to swap Firebase projects per environment (dev / staging /
  prod) without changing source code.

If you prefer, you can replace the env-file approach with `flutterfire configure`
in CI by authenticating via a Firebase service account or `FIREBASE_TOKEN` and
letting the CLI write `google-services.json`, `GoogleService-Info.plist`, and
`lib/firebase_options.dart` before the build.  The `flutter_with_secrets.sh`
script provides a simpler mechanism that works without additional tooling.

## GitHub Actions / CI usage

The workflow in `.github/workflows/mobile_build.yml` expects the following
GitHub secrets:

| Secret name | Purpose |
|-------------|---------|
| `FIREBASE_ENV_FILE` | Entire contents of `.env.firebase` (copy-paste it into a GitHub secret). |
| `ANDROID_GOOGLE_SERVICES_JSON` | Base64-encoded `google-services.json`. |
| `IOS_GOOGLE_SERVICE_INFO_PLIST` | Base64-encoded `GoogleService-Info.plist`. |

To create the base64 strings locally:

```bash
base64 < android/app/google-services.json > /tmp/google-services.b64
base64 < ios/Runner/GoogleService-Info.plist > /tmp/GoogleService-Info.b64
```

Copy the contents of those `.b64` files into the matching GitHub secrets.  The
workflow decodes them into `.secrets/firebase/...` and then calls
`scripts/flutter_with_secrets.sh` for `flutter pub get`, `flutter build apk`,
and `flutter build ipa --no-codesign`.  Artifacts (`app-release.apk` and
`Runner.ipa`) are uploaded for download from the Actions run.

If you need signed builds or automatic store uploads, add steps after the
Flutter build to run Fastlane with your signing keys (also injected via Actions
secrets).  The current workflow focuses on producing unsigned artifacts that you
can sign/distribute later.
