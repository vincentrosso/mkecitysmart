# Production device push testing

This repo includes admin/mod-only callable functions meant to help validate push delivery on real devices:

- `testPushToSelf` (callable): sends a push to the caller's currently registered device token (if your client registered it).
- `simulateNearbyWarning` (callable): sends a multicast push to devices near a coordinate (admin/mod only).

## 1) Prerequisites

- Your Firebase project: `mkeparkapp-1ad15`
- You have **one user account that is admin/mod** (custom claim or whatever your backend checks).
- The app build you’re testing is signed / TestFlight (for production APNs) and includes the iOS entitlement `aps-environment=production`.

## 2) Ensure device tokens are registered

Open the app on each phone and grant notification permission.

The app should:
- obtain an FCM token
- call the callable function `registerDevice`

If registration is working, you’ll see a `/devices/...` document created for each device in Firestore.

## 3) Get a Firebase Auth ID token for your admin/mod user

You need a Firebase Auth **ID token** to call admin/mod-only callables from a script.

Options:
- Add a temporary debug button in the app to print `await FirebaseAuth.instance.currentUser?.getIdToken()`.
- Use an existing internal admin screen/tool if you already have one.

Then set it in your environment:

```zsh
export FIREBASE_ID_TOKEN="<paste token>"
```

## 4) Send a nearby test warning

From `functions/`:

```zsh
node tools/prod_call_simulate_nearby_warning.js --lat 43.0389 --lng -87.9065 --radius-miles 5
```

If you have two phones and their registered device locations are within ~5 miles of the coordinate, the nearby phone(s) should receive a push.

## Troubleshooting

- If the script returns PERMISSION_DENIED: your ID token is not for an admin/mod account.
- If it returns OK but nobody gets a push:
  - verify each device has notifications enabled
  - verify each device is in `/devices` and has a valid `token`
  - verify FCM/APNs is configured (iOS `GoogleService-Info.plist` correct + `aps-environment` entitlement)
