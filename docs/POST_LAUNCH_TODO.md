# MKE CitySmart — Post-Launch TODO

> **Created:** February 9, 2026
> **Last Updated:** February 13, 2026
> **Current Version:** 1.0.75+79
> **Apple App Store:** Submitted for review v1.0.67+70 (manual release)
> **Google Play Store:** Closed testing Alpha — Release 72 (1.0.68) in review, 5 testers

---

## 🟢 1. RevenueCat / In-App Subscriptions

### What's Already Done (Code Complete)
| Item | File | Status |
|------|------|--------|
| `purchases_flutter: ^8.8.1` in pubspec | `pubspec.yaml:68` | ✅ Installed |
| `purchases_ui_flutter: ^8.11.0` in pubspec | `pubspec.yaml:71` | ✅ Installed |
| `SubscriptionService` singleton | `lib/services/subscription_service.dart` | ✅ Full implementation |
| RevenueCat SDK init with platform keys | `subscription_service.dart:68-148` | ✅ iOS key set, Android placeholder |
| Purchase flow (`purchase()`, `restorePurchases()`) | `subscription_service.dart:200-280` | ✅ Complete |
| RevenueCat native paywall UI (`presentPaywall()`) | `subscription_service.dart:370-420` | ✅ Complete |
| Customer Center (`presentCustomerCenter()`) | `subscription_service.dart:430-445` | ✅ Complete |
| Login/logout with RevenueCat user IDs | `subscription_service.dart:155-195` | ✅ Complete |
| `SubscriptionPlan` model (Free / Pro tiers) | `lib/models/subscription_plan.dart` | ✅ Complete |
| `PremiumFeature` enum (10 features) | `lib/models/subscription_plan.dart` | ✅ Complete |
| `FeatureGate` widget (access control wrapper) | `lib/widgets/feature_gate.dart` | ✅ Complete |
| `PaywallScreen` (custom paywall bottom sheet) | `lib/widgets/paywall_widget.dart` (699 lines) | ✅ Complete |
| `SubscriptionScreen` (plan comparison + manage) | `lib/screens/subscription_screen.dart` (860 lines) | ✅ Complete |
| AdMob integration (free-tier ads) | `lib/services/ad_service.dart`, `lib/widgets/ad_widgets.dart` | ✅ Complete |
| User attributes sync to RevenueCat | `subscription_service.dart:460-475` | ✅ Complete |

### What's Pending (Store + Dashboard Config)

#### Apple App Store Connect
- [x] **Create Subscription Group** — "CitySmart Pro" ✅
- [ ] **Create Monthly Product** — Product ID: `citysmart_pro_monthly_2026`, $4.99/month
- [ ] **Create Yearly Product** — Product ID: `citysmart_pro_yearly_2026`, $39.99/year
- [x] **Add subscription description & review screenshot** ✅
- [x] **Submit IAP for review** ✅

#### Google Play Console
- [ ] **Create Monthly Subscription** — `citysmart_pro_monthly_2026`, $4.99/month
- [ ] **Create Yearly Subscription** — `citysmart_pro_yearly_2026`, $39.99/year
- [x] **Set up base plan and offers** ✅

#### RevenueCat Dashboard (https://app.revenuecat.com)
- [x] **Verify iOS app config** — API key `appl_nPogZtDlCliLIbcHVwxxguJacpq` is set ✅
- [x] **Add Google Play app** — `goog_UfVOclLbKRHTgvZmywUdbmeJEVs` set, service account JSON uploaded ✅ (Feb 9)
- [x] **Replace Android placeholder key** — Real key `goog_UfVOclLbKRHTgvZmywUdbmeJEVs` in code ✅ (Feb 9)
- [ ] **Create Products in RevenueCat** — Map `citysmart_pro_monthly_2026` and `citysmart_pro_yearly_2026` to both stores
- [x] **Create Offering** — Default offering with monthly + yearly packages ✅
- [x] **Create Entitlement** — `pro` entitlement linked to both products ✅
- [x] **Set up App Store Connect Shared Secret** ✅
- [x] **Set up Google Play service account** — JSON uploaded, validation configured ✅
- [ ] **Configure Customer Center** — Cancellation flows, feedback surveys

#### Code Changes Needed
- [x] **Replace Android API key** — Real key `goog_UfVOclLbKRHTgvZmywUdbmeJEVs` in code ✅ (Feb 9)
- [ ] **Test sandbox purchases on iOS** — Use App Store sandbox test account
- [ ] **Test license purchases on Android** — Add license testers in Play Console
- [ ] **Verify paywall displays real products** — Currently shows static plan cards when offerings unavailable
- [ ] **Test restore purchases flow** — Ensure cross-device restore works
- [x] **Version bump** — Now at 1.0.75+79 ✅

### RevenueCat Keys Reference
| Platform | Key | Status |
|----------|-----|--------|
| iOS | `appl_nPogZtDlCliLIbcHVwxxguJacpq` | ✅ Set in code |
| Android | `goog_UfVOclLbKRHTgvZmywUdbmeJEVs` | ✅ Set in code (Feb 9) |
| Test/Dev | `test_JhJpIJnyYopCsUtcPVYZKarOQEO` | ✅ Available (sandbox only) |

### Product IDs (Must Match Across All Platforms)
| Product | ID | Price |
|---------|----|-------|
| Pro Monthly | `citysmart_pro_monthly_2026` | $4.99/mo |
| Pro Yearly | `citysmart_pro_yearly_2026` | $39.99/yr (~33% savings) |

### Entitlements
| Entitlement ID | Grants Access To |
|----------------|-----------------|
| `pro` | Ad-free, heatmaps, smart alerts, AI parking finder, tow helper, extended history, expanded radius, unlimited alerts, priority support |

---

## 🟡 2. Google Play Store — Production Launch

### Closed Testing Requirements
- [x] **Set up closed testing Alpha track** — Release 72 (1.0.68) uploaded and in review
- [x] **Upload AAB to closed testing** — v1.0.68+72 (75MB)
- [x] **Opt-in link:** `https://play.google.com/apps/testing/com.mkecitysmart.app`
- [ ] **Recruit 12 testers** — Need 12 unique Gmail accounts opted-in to closed testing
- [ ] **Current testers (5):** includes `getitdonewisconsin@gmail.com`, `dwaynesampson253@gmail.com`
- [ ] **Need 7 more testers** — Friends, family, Milwaukee community members
- [ ] **Wait 14 days** — Google requires 14 continuous days of closed testing
- [ ] **Earliest production eligible:** ~February 23, 2026 (if 12 testers onboarded by Feb 9)
- [ ] **Submit for production review** — After 14 days with 12 testers

### Pending Google Play Items
- [x] **Google Play policy fix** — Added source attributions to all 6 data screens + disclaimer on profile
- [x] **Play Store description updated** — Disclaimer + 7 official source URLs added
- [ ] **READ_MEDIA_IMAGES justification** — Submitted, awaiting approval
- [ ] **Production store listing review** — Verify all screenshots, descriptions finalized

---

## 🟡 3. Post-Launch Feature Updates

### v1.0.68 — Subscriptions Live
- [ ] RevenueCat products configured on both stores
- [ ] Android API key updated
- [ ] Paywall shows real prices from store
- [ ] Sandbox/license testing complete
- [ ] Submit update to both stores

### v1.0.69+ — Feature Improvements
- [ ] Push notification deep links
- [ ] Widget for iOS home screen (parking status)
- [ ] Live enforcement tracking improvements
- [ ] Parking meter payment integration research
- [ ] Performance optimizations based on Crashlytics data

---

## 📋 Account & Credential Reference

### App Store Review Account
- **Email:** `playstore-review@mkecitysmart.app`
- **Password:** `ReviewMKE2026!`
- **Firebase UID:** `VIVBP7jqUYY8jTnJDfSWN1zDPyd2`

### App IDs
- **Apple App ID:** 6756332812
- **Apple SKU:** mkesku
- **Bundle ID:** `com.mkecitysmart.app`
- **AdMob App ID:** `ca-app-pub-2009498889741048~9019853313`

### Firebase Project
- **Project ID:** `mkeparkapp-1ad15`
- **Hosting:** `https://mkeparkapp-1ad15.web.app`
- **Privacy Policy:** `https://mkeparkapp-1ad15.web.app/privacy.html`
- **Delete Account:** `https://mkeparkapp-1ad15.web.app/delete-account.html`

### Android Signing
- **Keystore:** `android/upload-keystore.jks` (gitignored)
- **Backup:** `~/upload-keystore-BACKUP.jks`
- **Alias:** `upload`
- **Store/Key Password:** `mkecitysmart2026`

---

## ✅ Completed (This Session — Feb 9, 2026)

- [x] iOS IPA built v1.0.67+70 and uploaded via Xcode Organizer
- [x] Android signing configured (keystore + key.properties + build.gradle.kts + proguard)
- [x] Release AAB built (78.2MB) with AD_ID permission
- [x] Google Play internal testing release rolled out
- [x] Google Play "Set up your app" forms all completed
- [x] Google Play store listing (copy, icon, feature graphic, screenshots, tags)
- [x] App Store Connect build uploaded
- [x] App Store Connect screenshots (iPhone 6.5" + iPad 13")
- [x] App Store Connect description, keywords, metadata filled
- [x] App Store Connect App Privacy completed (12 data types)
- [x] App Store Connect Content Rights, Age Rating, Encryption
- [x] App Store Connect submitted for review
- [x] Firebase Hosting: privacy.html + delete-account.html deployed
- [x] Firebase Auth test account created for store reviewers
- [x] Google Play REJECTED for Misleading Claims — fixed with source attributions
- [x] Added DataSourceAttribution widget + GovernmentDataDisclaimer to 6 screens + profile
- [x] Play Store description updated with disclaimer + 7 official source URLs
- [x] Version bumped to 1.0.68+72, AAB rebuilt (75MB)
- [x] Closed testing Alpha track set up — Release 72 in review
- [x] Firebase domain verification for mkecitysmart.com — VERIFIED ✅
- [x] Firebase Auth email templates customized (sender: noreply@mkecitysmart.com)
- [x] Firebase "Delete User Data" extension installed (auto-cleanup on account deletion)
- [x] APP_FEATURES.md created for sharing/AirDrop
- [x] All code committed and pushed (latest: d6e67cf)
