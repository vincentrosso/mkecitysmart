# MKE CitySmart — Project Notes

> **Last updated:** February 9, 2026
> **Version:** 1.0.67+70
> **Package:** `mkecitysmart`
> **Repository:** [Dwayne-26/Mke-CitySmart-app_flutter](https://github.com/Dwayne-26/Mke-CitySmart-app_flutter)
> **Tests:** 209 passing · 0 failing · `flutter analyze` clean
> **Apple App Store:** Submitted for review (v1.0.67, build 70)
> **Google Play Store:** Internal testing live (release 70), closed testing pending
> **Post-launch TODO:** See `docs/POST_LAUNCH_TODO.md`

---

## 🏙️ What Is CitySmart?

**MKE CitySmart** is a cross-platform Flutter app that helps Milwaukee drivers
navigate city parking intelligently. It combines real-time crowdsourced parking
data, AI-powered risk predictions, municipal schedules, and community-driven
alerts into a single app — so you never get a ticket, miss a street sweeping
day, or circle the block for 20 minutes looking for a spot.

The app is built for **Milwaukee first** but architecturally designed to scale
to **any U.S. city** (`wi/milwaukee` → `wi/madison` → `il/chicago` → anywhere).

---

## 📱 App Overview

### Platform Support
| Platform | Status |
|----------|--------|
| iOS      | ✅ Production (App Store via Codemagic) |
| Android  | ✅ Production (AAB + APK via Codemagic) |
| Web      | ✅ Functional (Flutter Web) |
| macOS    | 🔧 Desktop stub |
| Linux    | 🔧 Desktop stub |
| Windows  | 🔧 Desktop stub |

### Tech Stack
| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.35.7 / Dart ≥ 3.9.2 |
| State Management | Provider ^6.1.2 |
| Local Database | Drift + SQLite |
| Cloud Database | Cloud Firestore |
| Auth | Firebase Auth (Email, Google Sign-In, Sign in with Apple) |
| Push Notifications | Firebase Cloud Messaging + flutter_local_notifications |
| Analytics | Firebase Analytics + Firebase Crashlytics |
| Maps | flutter_map + latlong2 |
| GPS | geolocator + geocoding |
| Ads | Google AdMob (google_mobile_ads) |
| Subscriptions | RevenueCat (purchases_flutter) |
| OCR | Google ML Kit Text Recognition |
| CI/CD | Codemagic (iOS → App Store, Android → AAB/APK) |
| Fonts | Poppins, Inter |

### Design System
- **Dark theme** with custom color palette:
  - `kCitySmartGreen` (#081D19) — main background
  - `kCitySmartCard` (#0C241F) — cards and tiles
  - `kCitySmartYellow` (#E0C164) — accent, buttons, highlights
  - `kCitySmartText` (#FDF7EC) — primary text
  - `kCitySmartMuted` (#9BA59C) — secondary/muted text
  - Card borders: `Color(0xFF1F3A34)`

---

## 🗂️ Codebase Structure

```
lib/                          42,863 lines of Dart
├── main.dart                 App entry point, Firebase bootstrap, error handling
├── firebase_bootstrap.dart   Firebase init with fallback for web/test
├── firebase_options.dart     Generated Firebase config
│
├── screens/                  39 screens
│   ├── citysmart_shell_screens.dart  Bottom nav shell (Dashboard, Feed, Map, Alerts, Profile)
│   ├── dashboard_screen.dart         Main dashboard with quick actions
│   ├── parking_screen.dart           Core parking info hub
│   ├── parking_heatmap_screen.dart   Citation risk heat map (premium)
│   ├── parking_finder_screen.dart    AI-powered safest spot finder
│   ├── street_sweeping_screen.dart   Sweeping schedules + reminders
│   ├── alternate_side_parking_screen.dart  Alternate side rules
│   ├── ticket_tracker_screen.dart    Ticket history + lookup
│   ├── ticket_workflow_screen.dart   Pay/dispute ticket flows
│   ├── permit_screen.dart            Permit info hub
│   ├── permit_workflow_screen.dart   Permit application flow
│   ├── vehicle_management_screen.dart  Add/manage vehicles
│   ├── garbage_schedule_screen.dart  Garbage/recycling pickup
│   ├── charging_map_screen.dart      EV charging station map
│   ├── tow_helper_screen.dart        Tow recovery guide
│   ├── subscription_screen.dart      Pro upgrade paywall
│   ├── profile_screen.dart           User profile
│   ├── auth_screen.dart              Login / signup
│   ├── onboarding_screen.dart        First-run experience
│   └── ... (20 more)
│
├── services/                 37 services
│   ├── parking_crowdsource_service.dart   Crowdsourced report CRUD + geohash + aggregation
│   ├── zone_aggregation_service.dart      Zone-level data rollups for scaling
│   ├── parking_prediction_service.dart    AI parking safety predictions
│   ├── parking_risk_service.dart          Citation risk zones from Cloud Functions
│   ├── ticket_risk_prediction_service.dart  Ticket risk engine
│   ├── citation_hotspot_service.dart      Citation hotspot analysis
│   ├── citation_analytics_service.dart    Citation pattern analytics
│   ├── risk_alert_service.dart            Push-driven risk alerts
│   ├── weather_service.dart               NWS weather API
│   ├── street_segment_service.dart        Street-level parking rules
│   ├── alternate_side_parking_service.dart  Alternate side logic + notifications
│   ├── garbage_schedule_service.dart      ArcGIS garbage schedule
│   ├── notification_service.dart          FCM + local notification management
│   ├── subscription_service.dart          RevenueCat subscription management
│   ├── ad_service.dart                    AdMob ad lifecycle management
│   ├── user_repository.dart               Firestore + Drift user data sync
│   ├── saved_places_service.dart          Saved locations with alerts
│   ├── location_service.dart              GPS position wrapper
│   ├── cache_service.dart                 SharedPreferences with TTL
│   ├── cloud_log_service.dart             Firestore event logging
│   ├── analytics_service.dart             Firebase Analytics + Crashlytics
│   └── ... (15 more)
│
├── models/                   23 models
│   ├── parking_report.dart         Crowdsource report + SpotAvailability
│   ├── crowdsource_zone.dart       Zone aggregates for scaling
│   ├── parking_prediction.dart     SafeParkingSpot prediction
│   ├── parking_zone.dart           Parking zone rules
│   ├── parking_event.dart          Parking history events
│   ├── ticket.dart                 Citation/ticket records
│   ├── violation_record.dart       Violation history
│   ├── permit.dart                 Parking permits
│   ├── permit_eligibility.dart     Permit eligibility check
│   ├── vehicle.dart                User vehicles
│   ├── user_profile.dart           User profile
│   ├── subscription_plan.dart      Free/Pro tiers + premium features
│   ├── street_sweeping.dart        Sweeping schedules
│   ├── garbage_schedule.dart       Trash/recycling schedules
│   ├── saved_place.dart            Saved locations
│   ├── sighting_report.dart        Community sighting reports
│   ├── ev_station.dart             EV charging stations
│   └── ... (6 more)
│
├── widgets/                  14 widgets
│   ├── crowdsource_widgets.dart       Live parking banner + report sheet
│   ├── feature_gate.dart              Premium feature access control
│   ├── paywall_widget.dart            Subscription paywall UI
│   ├── parking_risk_badge.dart        Risk level badge display
│   ├── ad_widgets.dart                Banner + interstitial ad wrappers
│   ├── alternate_side_parking_card.dart  ASP dashboard card
│   └── ... (8 more)
│
├── providers/                2 providers
│   ├── user_provider.dart          Auth, profile, subscription, vehicles
│   └── location_provider.dart      GPS tracking
│
└── theme/
    ├── app_theme.dart              Dark theme definition
    └── app_colors.dart             Color constants
```

### Test Suite

```
test/                         30 test files · 3,915 lines · 209 tests
├── models/
│   ├── crowdsource_zone_test.dart              Zone model tests
│   └── parking_report_test.dart                Report model tests
├── services/
│   ├── parking_crowdsource_service_test.dart    Geohash + aggregation tests
│   └── zone_aggregation_service_test.dart       Zone doc ID + summarise tests
├── unit/
│   ├── parking_prediction_service_test.dart     Prediction engine tests
│   ├── parking_risk_models_test.dart            Risk model tests
│   ├── weather_service_test.dart                Weather API tests
│   ├── user_provider_logic_test.dart            Auth state tests
│   ├── user_repository_test.dart                Firestore sync tests
│   ├── ticket_lookup_service_test.dart          Ticket API tests
│   ├── garbage_schedule_service_test.dart       Garbage schedule tests
│   ├── saved_place_model_test.dart              Saved places tests
│   └── ... (17 more)
└── widget/
    └── app_smoke_test.dart                      Full app bootstrap + tab switching
```

---

## 🚗 Core Features

### 1. Crowdsourced Parking Reports
**What it does:** Users report real-time parking conditions — open spots, taken
spots, leaving a spot, enforcement sightings, street sweeping, parking blocked —
and the data feeds into a live availability system for everyone nearby.

**Files:**
- `lib/models/parking_report.dart` — `ParkingReport` model with 8 report types,
  geohash, TTL-based expiration, upvote/downvote, `SpotAvailability` aggregation
- `lib/services/parking_crowdsource_service.dart` — Singleton service for
  submitting reports, real-time Firestore streams (geohash prefix queries),
  static `aggregateAvailability()` for pure signal aggregation, upvote/downvote
- `lib/widgets/crowdsource_widgets.dart` — `CrowdsourceAvailabilityBanner`
  (live spot count banner), `CrowdsourceReportSheet` (bottom sheet for
  reporting), crowdsource map overlay markers
- `firestore.rules` — `parkingReports` collection with auth + field validation
- `firestore.indexes.json` — Composite indexes for geohash + timestamp queries

**Report Types:**
| Type | Signal | TTL |
|------|--------|-----|
| `spotAvailable` | Available (+) | 15 min |
| `leavingSpot` | Available (+) | 10 min |
| `spotTaken` | Taken (−) | 30 min |
| `parkedHere` | Taken (−) | 120 min |
| `enforcementSpotted` | Enforcement ⚠️ | 45 min |
| `towTruckSpotted` | Enforcement ⚠️ | 60 min |
| `streetSweepingActive` | Taken (−) | 120 min |
| `parkingBlocked` | Taken (−) | 180 min |

**How it works:**
1. User taps "Report" → picks a report type from the bottom sheet
2. Report is geolocated, geohashed (precision 7 ≈ 150m), and saved to Firestore
3. Nearby users see the report on the map as a colored marker
4. Reports expire automatically based on TTL
5. `aggregateAvailability()` computes a real-time `SpotAvailability` summary:
   available signals, taken signals, enforcement signals, availability score
   (0.0–1.0), estimated open spots

### 2. Zone-Based Scaling Architecture
**What it does:** Aggregates individual crowdsource reports into geographic
"zones" (~150m × 150m) that accumulate historical patterns over time. This
powers the "~X spots open nearby" feature and enables scaling to any city.

**Files:**
- `lib/models/crowdsource_zone.dart` — `CrowdsourceZone` model with region
  path, geohash, time-series data (hourly/daily averages), enforcement peaks,
  confidence scoring, `RegionAvailabilitySummary`
- `lib/services/zone_aggregation_service.dart` — Singleton for zone CRUD,
  real-time streams, report-to-zone aggregation, hourly/daily snapshot recording,
  region summaries, nearby spot count streams

**Region Architecture:**
```
wi/milwaukee          ← Default region (Milwaukee County)
wi/madison            ← Future expansion
il/chicago            ← Future expansion
il/cook/chicago       ← Nested regions supported
```

**Zone Document ID Format:**
```
{region}_{geohash7}
Example: wi_milwaukee_dp9dtpp
```

**Zone Data Model:**
- Live counters: `estimatedOpenSpots`, `activeReports`, `activeTakenSignals`,
  `activeAvailableSignals`, `enforcementActive`, `sweepingActive`, `parkingBlocked`
- Historical patterns: `hourlyAvgOpenSpots` (24-hour map), `dailyAvgOpenSpots`
  (7-day map), `enforcementPeakHours`
- Confidence: `confidenceScore` (0.0–1.0, log curve based on report volume),
  `uniqueReporters`
- Metadata: `region`, `geohash`, `name`, `latitude`, `longitude`, `totalReportsAllTime`

**How it works:**
1. When a report is submitted → `zone_aggregation_service` finds or creates the
   corresponding zone document in Firestore
2. Zone counters are atomically updated via Firestore transactions
3. Rolling averages are recorded hourly/daily for pattern detection
4. The banner widget subscribes to `nearbySpotCountStream()` → shows "~12 spots
   open nearby"
5. `summariseRegion()` aggregates all zones into a `RegionAvailabilitySummary`
   (total spots, coverage %, blind spots, enforcement zones)

### 3. Citation Risk Heat Map (Premium)
**What it does:** Shows a color-coded map of citation risk zones so users know
which blocks to avoid parking on. Premium feature gated by subscription tier.

**Files:**
- `lib/screens/parking_heatmap_screen.dart` — Interactive flutter_map with risk
  zone circles, crowdsource report markers, safest spot finder, zone detail cards
- `lib/services/parking_risk_service.dart` — Cloud Functions–backed risk zones
  with high/medium/low risk levels

### 4. AI Parking Predictions
**What it does:** Finds the safest parking spots near the user by analyzing
citation history, time of day, day of week, weather, and crowdsource data.

**Files:**
- `lib/services/parking_prediction_service.dart` — `findSafestSpotsNearby()`
  returns ranked `SafeParkingSpot` results with safety scores
- `lib/models/parking_prediction.dart` — `SafeParkingSpot` model with safety
  score, distance, recommendation reasons
- Crowdsource integration: `aggregateAvailability()` shifts the prediction
  safety score by up to ±15% based on real-time community data

### 5. Ticket Management
**What it does:** Look up, track, pay, and dispute parking tickets. OCR
scanning auto-fills ticket details from a photo.

**Files:**
- `lib/screens/ticket_tracker_screen.dart` — Ticket list with search
- `lib/screens/ticket_workflow_screen.dart` — Pay/dispute flow
- `lib/services/ticket_lookup_service.dart` — Ticket API client
- `lib/services/ticket_ocr_service.dart` — ML Kit OCR for ticket scanning
- `lib/services/citation_analytics_service.dart` — Citation pattern analysis
- `lib/models/ticket.dart` — Ticket data model

### 6. Street Sweeping & Alternate Side Parking
**What it does:** Schedules and push notification reminders for street sweeping
days and alternate side parking rules so you never get towed.

**Files:**
- `lib/screens/street_sweeping_screen.dart` — Sweeping schedule display
- `lib/screens/alternate_side_parking_screen.dart` — Alternate side rules
- `lib/services/alternate_side_parking_service.dart` — Rule lookup + notification scheduling
- `lib/models/street_sweeping.dart` — Schedule model

### 7. Permits
**What it does:** Check permit eligibility, view active permits, and apply for
new parking permits through a guided workflow.

**Files:**
- `lib/screens/permit_screen.dart` — Permit info hub
- `lib/screens/permit_workflow_screen.dart` — Application flow
- `lib/models/permit.dart` — Permit model
- `lib/models/permit_eligibility.dart` — Eligibility rules

### 8. Vehicle Management
**What it does:** Add and manage your vehicles (plate number, make, model, color)
so all parking features are personalized.

**Files:**
- `lib/screens/vehicle_management_screen.dart` — Vehicle CRUD screen
- `lib/models/vehicle.dart` — Vehicle model

### 9. Garbage & Recycling Schedules
**What it does:** Look up your garbage/recycling pickup day by address using
Milwaukee's ArcGIS data service.

**Files:**
- `lib/screens/garbage_schedule_screen.dart` — Schedule display
- `lib/services/garbage_schedule_service.dart` — ArcGIS API client
- `lib/models/garbage_schedule.dart` — Schedule model

### 10. EV Charging Map
**What it does:** Find nearby EV charging stations on an interactive map.

**Files:**
- `lib/screens/charging_map_screen.dart` — Charging station map
- `lib/services/open_charge_map_service.dart` — OpenChargeMap API
- `lib/models/ev_station.dart` — Station model

### 11. Risk Alerts & Notifications
**What it does:** Push notifications for high tow risk, citation risk,
enforcement sightings, and community alerts.

**Files:**
- `lib/services/risk_alert_service.dart` — Risk-based alert triggers
- `lib/services/notification_service.dart` — FCM + local notifications
- `lib/screens/alerts_landing_screen.dart` — Alert feed
- `lib/screens/alert_detail_screen.dart` — Alert detail view

### 12. Saved Places
**What it does:** Save frequently visited locations with custom alerts and
parking preferences.

**Files:**
- `lib/screens/saved_places_screen.dart` — Saved places management
- `lib/services/saved_places_service.dart` — Saved places CRUD
- `lib/models/saved_place.dart` — Place model

### 13. Community Sightings & Feed
**What it does:** Users report sightings (enforcement, events, road closures)
and browse a community feed.

**Files:**
- `lib/screens/report_sighting_screen.dart` — Report a sighting
- `lib/screens/feed_screen.dart` — Community feed
- `lib/models/sighting_report.dart` — Sighting model

### 14. Tow Recovery Helper
**What it does:** Step-by-step guide if your car gets towed — find the tow lot,
check fees, navigate there.

**Files:**
- `lib/screens/tow_helper_screen.dart` — Guided tow recovery

### 15. Subscription & Monetization
**What it does:** Two-tier subscription model (Free / Pro) with feature gating,
a paywall, and AdMob ads for free-tier users.

**Tiers:**
| Feature | Free | Pro ($4.99/mo) |
|---------|------|----------------|
| Basic parking info | ✅ | ✅ |
| Street sweeping reminders | ✅ | ✅ |
| Crowdsource parking reports | ✅ | ✅ |
| Live spot counts | ❌ | ✅ |
| Citation Risk Heat Map | ❌ (7-day trial) | ✅ |
| AI Parking Finder | ❌ | ✅ |
| Tow Recovery Helper | ❌ | ✅ |
| Smart Alerts | ❌ | ✅ |
| Ad-Free Experience | ❌ | ✅ |
| Extended History (1 yr) | ❌ | ✅ |
| Priority Support | ❌ | ✅ |
| Expanded Radius (15 mi) | ❌ | ✅ |
| Unlimited Alerts | ❌ | ✅ |

**Gating implementation:**
- `FeatureGate` widget wraps premium screen bodies (heatmap, parking finder, tow helper)
- `FeatureGate.hasAccess()` static method used for inline checks (spot counts in banner)
- `PremiumFeature` enum (10 values) mapped to display names, icons, and minimum tiers
- `SubscriptionPlan.hasFeature()` checks plan booleans per feature

**Files:**
- `lib/services/subscription_service.dart` — RevenueCat integration
- `lib/models/subscription_plan.dart` — `SubscriptionTier`, `PremiumFeature`
- `lib/widgets/feature_gate.dart` — Access control wrapper
- `lib/widgets/paywall_widget.dart` — Upgrade prompt
- `lib/services/ad_service.dart` — AdMob banner, interstitial, rewarded ads
- `lib/screens/subscription_screen.dart` — Pro upgrade screen

### 16. User Authentication
**What it does:** Multi-provider auth with Firebase — email/password, Google
Sign-In, Sign in with Apple. Guest mode supported.

**Files:**
- `lib/screens/auth_screen.dart` — Login UI
- `lib/screens/register_screen.dart` — Registration UI
- `lib/screens/onboarding_screen.dart` — First-run experience
- `lib/providers/user_provider.dart` — Auth state, profile, subscription tier
- `lib/services/user_repository.dart` — Firestore + Drift sync

---

## 🔥 Firestore Collections

| Collection | Purpose |
|-----------|---------|
| `parkingReports` | Individual crowdsource parking reports |
| `crowdsourceZones` | Aggregated zone-level parking intelligence |
| `users` | User profiles and preferences |
| `sightings` | Community sighting reports |
| `appLogs` | Cloud event logging |

---

## 🧪 Test Coverage

**209 tests across 30 test files:**

| Category | Tests | Files |
|----------|-------|-------|
| Crowdsource models | ~25 | `crowdsource_zone_test`, `parking_report_test` |
| Crowdsource services | ~28 | `parking_crowdsource_service_test`, `zone_aggregation_service_test` |
| Prediction engine | ~10 | `parking_prediction_service_test`, `parking_prediction_model_test` |
| Risk models | ~8 | `parking_risk_models_test` |
| User system | ~20 | `user_provider_test`, `user_provider_logic_test`, `user_repository_test` |
| Ticket services | ~6 | `ticket_lookup_service_test`, `ticket_api_service_test` |
| Weather | ~4 | `weather_service_test` |
| Garbage schedule | ~3 | `garbage_schedule_service_test` |
| Other unit tests | ~45 | Various service + model tests |
| Widget smoke test | ~60 | `app_smoke_test` (full app bootstrap + tab navigation) |

---

## 🛠️ Recent Implementation History

### Phase 1: Crowdsource Parking Reports Backend (Commit `88cdba6`)
- `ParkingReport` model with 8 report types, geohash encoding, TTL expiration
- `ParkingCrowdsourceService` with Firestore CRUD, real-time streams, geohash
  range queries, upvote/downvote, aggregation engine
- Firestore security rules for `parkingReports`
- Composite Firestore indexes (geohash + timestamp, userId + timestamp)
- 18 unit tests

### Phase 2: Crowdsource UI Layer (Commit `ad031b9`)
- `CrowdsourceAvailabilityBanner` — real-time availability banner with pulse
  animation, color-coded scores, enforcement warnings
- `CrowdsourceReportSheet` — bottom sheet for submitting reports with note field
- Map overlay — crowdsource report markers on the heatmap screen
- Prediction integration — crowdsource data shifts AI parking predictions ±15%

### Phase 3: Zone-Based Scaling Architecture (Commit `d52a950`)
- `CrowdsourceZone` model — geographic parking zones with time-series
  aggregation, confidence scoring, hourly/daily patterns
- `ZoneAggregationService` — zone CRUD, real-time streams, report-to-zone
  aggregation, region summaries, "~X spots open" spot count streams
- Region-agnostic paths: `wi/milwaukee` → `wi/madison` → `il/chicago`
- `ParkingReport` extended with `region` and `zoneId` fields
- `SpotAvailability` extended with `estimatedOpenSpots`
- Banner updated to show real spot counts ("~12 spots open nearby")
- `aggregateAvailability()` promoted to static (pure function)
- Firestore rules + indexes for `crowdsourceZones` collection
- 29 new tests (zone model, zone service, report region fields, spot counts)

### Phase 4: Formatting Cleanup (Commit `4f5c620`)
- Dart formatter whitespace and line-wrapping standardization

---

## 🚀 What's Next

### Scaling Roadmap
1. **Cloud Function triggers** — Auto-recalculate zones when reports expire
2. **Hourly snapshot cron** — Record hourly averages for pattern detection
3. **Admin dashboard** — Zone health monitoring, blind spot identification
4. **Region expansion** — Onboard Madison, Chicago, etc. via config
5. **Geofence alerts** — "5 spots just opened near your saved place"

### Feature Backlog
- Parking meter payment integration
- Live enforcement tracking (real-time GPS dots)
- Parking garage capacity feeds
- Carpooling / ride-share parking coordination
- Accessibility-focused parking spot tracking
- Municipal API integrations for real-time rule updates

---

## 📊 Project Stats

| Metric | Value |
|--------|-------|
| Dart code (lib/) | 42,863 lines |
| Test code | 3,915 lines |
| Test files | 30 |
| Passing tests | 209 |
| Screens | 39 |
| Services | 37 |
| Models | 23 |
| Widgets | 14 |
| Total commits | 544 |
| Current version | 1.0.67+70 |
