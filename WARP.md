# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project: MKE CitySmart – a Flutter app for Milwaukee parking regulations, risk alerts, permits, street sweeping, and municipal workflows.

Package name: mkecitysmart

Commands

- Install deps
  - flutter pub get

- Run (web, hot reload)
  - flutter run -d chrome

- Run (iOS simulator)
  - flutter run -d iphone

- Lint / static analysis
  - flutter analyze

- Tests
  - Run all: flutter test
  - Run with coverage: flutter test --coverage
  - Run a single test by name: flutter test --name 'partial or regex of test name'
  - Run a specific file: flutter test test/unit/weather_service_test.dart

- Format code
  - dart format -o write .

- Build (web)
  - Release build: flutter build web --release
  - Output: build/web/

- Build (iOS)
  - flutter build ipa --release

- Build (Android)
  - flutter build appbundle --release

- Regenerate mocks
  - dart run build_runner build --delete-conflicting-outputs

Architecture and code structure

- Entry point: lib/main.dart
  - Bootstraps Firebase, services (AdService, SubscriptionService, NotificationService, etc.), and Provider-based state.
  - Uses CitySmart shell with bottom navigation tabs.

- Shell / Navigation: lib/screens/citysmart_shell_screens.dart
  - Bottom nav tabs: Dashboard, Feed, Map, Alerts, Profile
  - Each tab hosts its own screen.

- Screens: lib/screens/*.dart (39 screens)
  - Key screens: dashboard_screen, landing_screen, parking_screen, permit_screen, permit_workflow_screen, street_sweeping_screen, alternate_side_parking_screen, history_screen, profile_screen, subscription_screen, auth_screen, onboarding_screen, parking_heatmap_screen, parking_finder_screen, ticket_tracker_screen, vehicle_management_screen

- Services: lib/services/*.dart (35 services)
  - Key services: ad_service (AdMob), subscription_service (RevenueCat), notification_service (FCM + local), parking_risk_service (Cloud Functions), weather_service (NWS API), user_repository (Firestore + Drift), alternate_side_parking_service, cache_service (SharedPreferences TTL)

- Models: lib/models/*.dart (21 models)
  - User profile, vehicle, ticket, permit, parking prediction, street sweeping, subscription plan, saved place, etc.

- Providers: lib/providers/*.dart
  - UserProvider – auth state, profile, subscription tier, vehicle management
  - LocationProvider – GPS position tracking

- State management: Provider (^6.1.2)
- Database: Drift + SQLite (local), Cloud Firestore (remote)
- Auth: Firebase Auth, Google Sign-In, Sign in with Apple
- Ads: google_mobile_ads (AdMob) via AdService singleton
- Subscriptions: RevenueCat (purchases_flutter) via SubscriptionService
- Push: firebase_messaging + flutter_local_notifications
- CI/CD: Codemagic (iOS to App Store, Android to AAB/APK)

Repo-specific notes

- The package was renamed from mkeparkapp_flutter to mkecitysmart. All imports use package:mkecitysmart.
- Remote repo: https://github.com/Dwayne-26/Mke-CitySmart-app_flutter.git
- Ad unit IDs for interstitial and rewarded ads need to be created in AdMob (see TODO(ads) in ad_service.dart).
- The backend/ folder contains a FastAPI health-check stub only. Real API endpoints are not yet built.
- Tests are in test/unit/ and test/widget/. Run flutter test --coverage to check coverage.
