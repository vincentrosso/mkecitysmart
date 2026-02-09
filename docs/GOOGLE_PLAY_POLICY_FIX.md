# MKE CitySmart — Google Play Policy Fix & Session Notes

> **Date:** February 9, 2026
> **Version:** 1.0.67+70
> **Issue:** Misleading Claims policy — Missing Source Links for Government Information

---

## 1. THE PROBLEM

Google Play rejected the app for **Misleading Claims policy violation**:

> "Your app provides government information but lacks one or more clear and accessible URL/link(s) to the original source(s) (for example, .gov domains)."

**What triggered it:** The app displays City of Milwaukee data (garbage schedules, parking rules, street sweeping, permits, ticket info) without citing the official government sources or disclaiming that we're not a government entity.

---

## 2. GOVERNMENT DATA SOURCES USED IN THE APP

| Feature | Data Source | Official URL |
|---------|-----------|-------------|
| Garbage & Recycling Schedule | Milwaukee DPW via ArcGIS | https://itmdapps.milwaukee.gov/DpwServletsPublic/garbage_day |
| Street Segments / Parking Rules | Milwaukee Maps ArcGIS | https://milwaukeemaps.milwaukee.gov/arcgis/rest/services/ |
| Alternate Side Parking | City of Milwaukee DPW | https://city.milwaukee.gov/dpw/infrastructure/Street-Maintenance/Alternate-Side-Parking |
| Street Sweeping | City of Milwaukee DPW | https://city.milwaukee.gov/dpw/infrastructure/Street-Maintenance/Street-Sweeping |
| Parking Tickets | City of Milwaukee | https://city.milwaukee.gov/parkingtickets |
| Permits | City of Milwaukee | https://city.milwaukee.gov/epermits |
| Weather Alerts | National Weather Service (NOAA) | https://api.weather.gov |
| EV Charging Stations | OpenChargeMap (community data) | https://openchargemap.org |

---

## 3. REQUIRED FIXES

### Fix A — Update Google Play Store Description

Replace the current Play Store description with this version that includes source citations and a disclaimer:

```
MKE CitySmart is the ultimate city companion app for Milwaukee residents, commuters, and visitors. Find parking, avoid tickets, and stay on top of everything happening in your city - all from one app.

DISCLAIMER: MKE CitySmart is an independent app and is NOT affiliated with, endorsed by, or operated by the City of Milwaukee or any government entity. All government data displayed in this app is sourced from publicly available official sources listed below.

SMART PARKING
- Interactive parking map with real-time availability zones
- Parking heatmap showing busy vs. open areas
- Parking finder with filters for price, distance, and time limits
- Crowdsourced parking reports from fellow Milwaukeeans
- Save your favorite parking spots for quick access

NEVER GET A TICKET AGAIN
- Alternate side parking rules with daily notifications
- Street sweeping schedule and alerts
- Parking meter expiration reminders
- Ticket tracker - log, photograph, and manage your parking tickets

CITY SERVICES AT YOUR FINGERTIPS
- Garbage & recycling collection schedule with pickup reminders
- EV charging station map for electric vehicle owners
- Local alerts and emergency notifications

PERSONALIZED FOR YOU
- Set your home and work locations for tailored info
- Vehicle management - track multiple cars and permits
- Customizable notification preferences
- Dark mode support

SMART NOTIFICATIONS
- Morning parking reminders before you leave
- Evening move-your-car warnings
- Street sweeping alerts by zone
- Garbage day reminders

PREMIUM FEATURES (optional subscription)
- Ad-free experience
- Extended parking history and analytics
- Priority city alerts

OFFICIAL DATA SOURCES:
- Parking rules & street data: City of Milwaukee Maps (milwaukeemaps.milwaukee.gov)
- Garbage & recycling schedules: Milwaukee DPW (itmdapps.milwaukee.gov)
- Alternate side parking: City of Milwaukee DPW (city.milwaukee.gov/dpw)
- Street sweeping schedules: City of Milwaukee DPW (city.milwaukee.gov/dpw)
- Parking tickets: City of Milwaukee (city.milwaukee.gov/parkingtickets)
- Weather alerts: National Weather Service / NOAA (weather.gov)
- EV charging stations: OpenChargeMap (openchargemap.org)

This app is not a government service. All city data is sourced from publicly available government APIs and websites. For official city services, visit city.milwaukee.gov.

Built for Milwaukee by a Milwaukee developer.
```

**Character count:** ~1,950 (well within 4,000 limit)

---

### Fix B — Add In-App Disclaimer

Add a disclaimer to the app's About/Settings screen. Suggested text:

```
MKE CitySmart is an independent application and is not affiliated with,
endorsed by, or operated by the City of Milwaukee, Milwaukee County, or
any government entity.

City data including parking rules, garbage schedules, street sweeping
schedules, and permit information is sourced from publicly available
City of Milwaukee APIs and websites. For official city services, visit
city.milwaukee.gov.

Data Sources:
- Parking & street data: milwaukeemaps.milwaukee.gov
- Garbage/recycling: itmdapps.milwaukee.gov
- Weather alerts: api.weather.gov (NOAA)
- EV charging: openchargemap.org
```

**Where to add it:** `lib/screens/profile_screen.dart` or a new "About" / "Legal" section accessible from the profile/settings screen.

---

### Fix C — Add Source Links In Relevant Screens

Each screen that shows government data should have a small "Source" link:

| Screen | Add This |
|--------|---------|
| Garbage Schedule Screen | "Source: City of Milwaukee DPW" with link to `city.milwaukee.gov/dpw` |
| Alternate Side Parking Screen | "Source: City of Milwaukee DPW" with link to `city.milwaukee.gov/dpw` |
| Street Sweeping Screen | "Source: City of Milwaukee DPW" with link to `city.milwaukee.gov/dpw` |
| Ticket Tracker Screen | "Source: city.milwaukee.gov/parkingtickets" (already partially there) |
| Parking Map / Heatmap | "Street data: milwaukeemaps.milwaukee.gov" |
| Weather Alerts | "Source: National Weather Service (weather.gov)" |
| EV Charging Map | "Source: OpenChargeMap (openchargemap.org)" |

---

## 4. IMPLEMENTATION CHECKLIST

### Google Play Console (No Code Required)
- [ ] Go to Play Console → Store Listing → Edit Description
- [ ] Replace full description with the updated version from Fix A above
- [ ] Save and review

### Code Changes Required
- [ ] Add disclaimer to profile/settings/about screen (Fix B)
- [ ] Add "Source: ..." footer links to each government data screen (Fix C)
- [ ] Bump version to 1.0.68+71
- [ ] Build new AAB: `flutter build appbundle --release`
- [ ] Upload new AAB to Play Console (internal testing → closed testing)
- [ ] Resubmit for review

### Verification Before Resubmitting
- [ ] Description contains "NOT affiliated with...government entity" disclaimer
- [ ] Description lists all official .gov source URLs
- [ ] In-app About/Legal screen has disclaimer and source links
- [ ] Each government data screen has a visible source attribution
- [ ] No language implies the app IS a government service

---

## 5. TIMELINE

| Step | Time |
|------|------|
| Update Play Store description | 5 minutes (Play Console only) |
| Add in-app disclaimer + source links (code) | 1-2 hours |
| Build + upload new AAB | 15 minutes |
| Google Play re-review | 1-3 days |

**Note:** You can update the Play Store description RIGHT NOW without a new build. The code changes (in-app disclaimer + source links) require a new build and upload.

---

---

# SESSION SUMMARY — February 9, 2026

## Everything We Did Today

### 1. iOS App Store Submission (COMPLETE)
- Built IPA v1.0.67+70
- Uploaded via Xcode Organizer
- Filled out all App Store Connect forms:
  - Description (plain text, no emojis)
  - Keywords, Support URL, Copyright (2026 Dwayne Sampson)
  - Screenshots: iPhone 6.5" (8 screenshots) + iPad 13" (2 screenshots)
  - App Privacy: 12 data types declared, tracking corrected
  - Content Rights, Age Rating (4+), Encryption exemption
  - Sign-in info for reviewers
  - Pricing: Free
- **Status: Submitted for Apple Review (manual release)**
- Expected review: 24-48 hours

### 2. Google Play Store Setup (IN PROGRESS)
- Generated upload keystore (JKS)
- Configured signing in build.gradle.kts
- Added ProGuard rules for ML Kit
- Built release AAB (78.2MB)
- Completed all "Set up your app" forms in Play Console
- Created store listing (copy, icon, feature graphic, screenshots)
- Internal testing release 70 rolled out
- **Blocker: Misleading Claims policy (this doc covers the fix)**
- **Blocker: Need 12 testers × 14 days for closed testing before production**

### 3. Firebase Domain Verification (FIXED)
- DNS records on GoDaddy had typo: `firebaseemail.com` → corrected to `firebasemail.com`
- All 4 records verified via `dig`:
  - TXT: `v=spf1 include:_spf.firebasemail.com ~all` ✅
  - TXT: `firebase=mkeparkapp-1ad15` ✅
  - CNAME: `firebase1._domainkey` → `...dkim1._domainkey.firebasemail.com` ✅
  - CNAME: `firebase2._domainkey` → `...dkim2._domainkey.firebasemail.com` ✅
- Waiting for Firebase to re-poll and verify

### 4. Post-Launch TODO Created
- Full RevenueCat integration checklist: `docs/POST_LAUNCH_TODO.md`
- Code is 90% complete — SubscriptionService, PaywallScreen, FeatureGate all built
- Pending: Create products in App Store Connect + Play Console + RevenueCat dashboard
- Pending: Replace `goog_PLACEHOLDER` Android API key

### 5. Revenue Projections

#### Year 1 (Milwaukee Only)
| Scenario | Ad Revenue | Sub Revenue | Total |
|----------|-----------|-------------|-------|
| Conservative | $9,200 | $2,076 | **$11,276** |
| Moderate | $40,200 | $7,788 | **$47,988** |
| Optimistic | $79,800 | $18,163 | **$97,963** |

#### Year 2 (Growth + Retention)
| Scenario | Ad Revenue | Sub Revenue | Total |
|----------|-----------|-------------|-------|
| Conservative | $38,400 | $9,600 | **$48,000** |
| Moderate | $162,000 | $36,000 | **$198,000** |
| Optimistic | $324,000 | $86,400 | **$410,400** |

#### Year 3 (Multi-City: Madison, Chicago, Minneapolis)
| Scenario | Ad Revenue | Sub Revenue | Total |
|----------|-----------|-------------|-------|
| Conservative | $115,200 | $28,800 | **$144,000** |
| Moderate | $540,000 | $120,000 | **$660,000** |
| Optimistic | $1,296,000 | $345,600 | **$1,641,600** |

#### Platform Revenue Split (US)
| Platform | % Downloads | % Revenue |
|----------|------------|-----------|
| iOS | ~45-50% | ~65-70% (higher eCPM + subscription conversion) |
| Android | ~50-55% | ~30-35% |

#### Key Revenue Levers
- Milwaukee local marketing (Reddit, Facebook, Marquette/UWM, local news)
- ASO — keywords like "Milwaukee parking", "parking tickets MKE"
- Referral program (Give 7 Get 7 days Premium — already built)
- Parking meter payments (future — transaction fees $0.25-$0.50 each)
- Multi-city expansion (architecture already supports wi/madison, il/chicago)
- B2B city partnerships (cities pay for data insights)

---

## ACCOUNT & CREDENTIALS REFERENCE

| Item | Value |
|------|-------|
| **Bundle ID** | `com.mkecitysmart.app` |
| **Apple App ID** | 6756332812 |
| **Apple SKU** | mkesku |
| **Firebase Project** | `mkeparkapp-1ad15` |
| **Hosting** | `https://mkeparkapp-1ad15.web.app` |
| **Privacy Policy** | `https://mkeparkapp-1ad15.web.app/privacy.html` |
| **Delete Account** | `https://mkeparkapp-1ad15.web.app/delete-account.html` |
| **AdMob App ID** | `ca-app-pub-2009498889741048~9019853313` |
| **RevenueCat iOS Key** | `appl_nPogZtDlCliLIbcHVwxxguJacpq` |
| **RevenueCat Android Key** | `goog_PLACEHOLDER` (needs real key) |
| **Review Account** | `playstore-review@mkecitysmart.app` / `ReviewMKE2026!` |
| **Android Keystore** | `android/upload-keystore.jks` (alias: upload, pass: mkecitysmart2026) |
| **Keystore Backup** | `~/upload-keystore-BACKUP.jks` |
| **Domain** | `mkecitysmart.com` (GoDaddy) |

---

## WHAT'S NEXT (Priority Order)

1. **Fix Google Play Misleading Claims** — Update description NOW (no build needed), then add in-app disclaimers + source links in code
2. **Wait for Apple approval** — 24-48 hours
3. **Wait for Firebase domain verification** — DNS is correct, Firebase needs to re-poll
4. **Recruit 10 more Google Play testers** — Need 12 total for 14 days of closed testing
5. **RevenueCat subscription setup** — After app is approved on both stores
6. **Version 1.0.68** — Submit update with disclaimers + working subscriptions
