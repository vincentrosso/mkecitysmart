# MKE CitySmart — Post-Launch TODO

> **Created:** February 9, 2026
> **Version submitted:** 1.0.67+70
> **Apple App Store:** Submitted for review (manual release)
> **Google Play Store:** Internal testing live, closed testing pending (need 12 testers × 14 days)

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
- [ ] **Create Subscription Group** — Go to App Store Connect → Your App → Subscriptions → Create Group (e.g., "CitySmart Pro")
- [ ] **Create Monthly Product** — Product ID: `citysmart_pro_monthly`, Price: $4.99/month, Reference name: "Pro Monthly"
- [ ] **Create Yearly Product** — Product ID: `citysmart_pro_yearly`, Price: $39.99/year, Reference name: "Pro Yearly"
- [ ] **Add subscription description & review screenshot** — Required for Apple review of IAP
- [ ] **Submit IAP for review** — Products go into "Waiting for Review" state

#### Google Play Console
- [ ] **Create Monthly Subscription** — Play Console → Monetize → Subscriptions → Product ID: `citysmart_pro_monthly`, $4.99/month
- [ ] **Create Yearly Subscription** — Product ID: `citysmart_pro_yearly`, $39.99/year
- [ ] **Set up base plan and offers** — Free trial (7 days recommended), introductory pricing

#### RevenueCat Dashboard (https://app.revenuecat.com)
- [ ] **Verify iOS app config** — API key `appl_nPogZtDlCliLIbcHVwxxguJacpq` is set
- [ ] **Add Google Play app** — Get `goog_` API key, add service account JSON for server validation
- [ ] **Replace Android placeholder key** — Update `_revenueCatApiKeyAndroid` in `subscription_service.dart` (currently `goog_PLACEHOLDER`)
- [ ] **Create Products in RevenueCat** — Map `citysmart_pro_monthly` and `citysmart_pro_yearly` to both stores
- [ ] **Create Offering** — Default offering with monthly + yearly packages
- [ ] **Create Entitlement** — `pro` entitlement linked to both products
- [ ] **Set up App Store Connect Shared Secret** — For server-side receipt validation
- [ ] **Set up Google Play service account** — For server-side receipt validation
- [ ] **Configure Customer Center** — Cancellation flows, feedback surveys

#### Code Changes Needed
- [ ] **Replace `goog_PLACEHOLDER`** in `lib/services/subscription_service.dart:23` with real Google Play API key from RevenueCat
- [ ] **Test sandbox purchases on iOS** — Use App Store sandbox test account
- [ ] **Test license purchases on Android** — Add license testers in Play Console
- [ ] **Verify paywall displays real products** — Currently shows static plan cards when offerings unavailable
- [ ] **Test restore purchases flow** — Ensure cross-device restore works
- [ ] **Version bump to 1.0.68** — Submit update with working subscriptions

### RevenueCat Keys Reference
| Platform | Key | Status |
|----------|-----|--------|
| iOS | `appl_nPogZtDlCliLIbcHVwxxguJacpq` | ✅ Set in code |
| Android | `goog_PLACEHOLDER` | ❌ Needs real key |
| Test/Dev | `test_JhJpIJnyYopCsUtcPVYZKarOQEO` | ✅ Available (sandbox only) |

### Product IDs (Must Match Across All Platforms)
| Product | ID | Price |
|---------|----|-------|
| Pro Monthly | `citysmart_pro_monthly` | $4.99/mo |
| Pro Yearly | `citysmart_pro_yearly` | $39.99/yr (~33% savings) |

### Entitlements
| Entitlement ID | Grants Access To |
|----------------|-----------------|
| `pro` | Ad-free, heatmaps, smart alerts, AI parking finder, tow helper, extended history, expanded radius, unlimited alerts, priority support |

---

## 🟡 2. Google Play Store — Production Launch

### Closed Testing Requirements
- [ ] **Recruit 12 testers** — Need 12 unique Gmail accounts opted-in to closed testing
- [ ] **Current testers (2):** `getitdonewisconsin@gmail.com`, `dwaynesampson253@gmail.com`
- [ ] **Need 10 more testers** — Friends, family, Milwaukee community members
- [ ] **Wait 14 days** — Google requires 14 continuous days of closed testing
- [ ] **Earliest production eligible:** ~February 23, 2026 (if 12 testers onboarded by Feb 9)
- [ ] **Submit for production review** — After 14 days with 12 testers

### Pending Google Play Items
- [ ] **READ_MEDIA_IMAGES justification** — Submitted, awaiting approval
- [ ] **Closed testing track setup** — Create closed testing track (not just internal)
- [ ] **Upload AAB to closed testing** — Current AAB: `app-release.aab` (78.2MB)
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
- [x] All code committed and pushed
