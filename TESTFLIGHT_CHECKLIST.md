# MKE CitySmart TestFlight Build Checklist
## Build Date: January 31, 2026
## Version: Phase 1 Complete (F-402, F-403, F-103, F-104)

---

## Pre-Flight Checks ✈️

### Build Verification
- [ ] Flutter analyze passes with no errors in lib/
- [ ] iOS archive builds successfully
- [ ] IPA uploaded to App Store Connect
- [ ] TestFlight processing complete

---

## New Feature Testing Checklist

### 1. Saved Places (F-103) 📍
**Navigate to:** Profile → Saved Places (or Dashboard → Saved Places tile)

#### Home Location
- [ ] Tap "Home" card → Editor sheet opens
- [ ] Tap "Use Current Location" → Location populates
- [ ] Enter a name → Save → Home card shows location
- [ ] Notification radius slider works (0.1 - 2.0 miles)
- [ ] Notifications toggle on/off works
- [ ] Edit home → Changes persist after app restart

#### Work Location
- [ ] Tap "Work" card → Editor sheet opens
- [ ] Set work location using current location
- [ ] Verify only ONE work location allowed (editing replaces)

#### Favorites
- [ ] Tap "Add Favorite" → Editor opens
- [ ] Add a favorite with custom name
- [ ] Verify favorite appears in list
- [ ] Swipe left on favorite → Delete confirmation
- [ ] Delete a favorite → Removed from list
- [ ] Add multiple favorites (up to 5 for basic test)

#### Persistence
- [ ] Force close app → Reopen → All places still saved
- [ ] Sign out → Sign in → Places restored from Firestore

---

### 2. Tow Helper (F-104) 🚗
**Navigate to:** Dashboard → Tow Helper tile

#### Recovery Guide Tab
- [ ] 5-step guide displays correctly
- [ ] Step 1: "Call Police" button → Phone dialer opens
- [ ] Step 3: "Get Directions" → Maps app opens
- [ ] Step 4: "See Fee Details" → Fee breakdown sheet opens
- [ ] Fee estimates display correctly ($145-275 tow, $25-40/day storage)
- [ ] Tips section displays (Enable Alerts, Check Sweeping, etc.)

#### Tow Lots Tab
- [ ] Milwaukee tow lots list displays
- [ ] Milwaukee Police Tow Lot shows "Primary" badge
- [ ] Each lot shows address, hours, phone
- [ ] "Call" button → Phone dialer opens
- [ ] "Directions" button → Maps app opens with route

#### Edge Cases
- [ ] No internet → Graceful error handling
- [ ] Phone number copy fallback works if dialer unavailable

---

### 3. Performance Improvements (F-402) ⚡
**Test offline behavior and caching**

#### Offline Mode
- [ ] Load app with internet → Data loads
- [ ] Turn on Airplane Mode → App still usable
- [ ] Saved places accessible offline
- [ ] Feed shows cached data (may be stale)
- [ ] Turn internet back on → Data refreshes

#### Firestore Persistence
- [ ] First app launch loads from network
- [ ] Second launch (same session) → Much faster loading
- [ ] After force close → Fast data loading from cache

---

### 4. Analytics & Crash Reporting (F-403) 📊
**Verify in Firebase Console after testing**

#### Analytics Events (check Firebase Analytics)
- [ ] Screen views tracked: FeedScreen, SavedPlacesScreen, TowHelperScreen
- [ ] Event: `feed_filters_changed` when adjusting feed filters
- [ ] Event: `saved_place_added` when adding a place
- [ ] Event: `saved_place_deleted` when removing a place
- [ ] Event: `tow_phone_call` when tapping call button
- [ ] Event: `tow_directions` when tapping directions

#### Crashlytics (check Firebase Crashlytics)
- [ ] App launches without crashes
- [ ] User ID bound to analytics (check user properties)
- [ ] No crashes during normal usage

---

### 5. Existing Features Regression Check

#### Dashboard
- [ ] Dashboard loads successfully
- [ ] All tiles display correctly
- [ ] New tiles visible: Tow Helper, Saved Places

#### Feed Screen
- [ ] Feed loads with sightings (if any exist)
- [ ] Filter bar works (radius, time)
- [ ] Pull-to-refresh works
- [ ] Pagination "Load More" works (if enough data)

#### Parking Heatmap
- [ ] Map loads with risk zones
- [ ] Risk badge shows current location risk
- [ ] Tapping zones shows info

#### Parking Finder
- [ ] Map loads with parking locations
- [ ] Tap marker → Details popup
- [ ] "Get Directions" works

#### Ticket Tracker
- [ ] Can add a new ticket (photo or manual)
- [ ] Ticket appears in Open tab
- [ ] Can mark as paid → Moves to Paid tab

#### User Profile
- [ ] Profile screen loads
- [ ] User info displays correctly
- [ ] "Saved Places" link navigates correctly
- [ ] Sign out works

#### Onboarding
- [ ] Fresh install shows onboarding (test on new device/simulator)
- [ ] Returning user skips onboarding

---

## Known Issues / Notes

1. **CocoaPods Warning**: The Xcode project base configuration warning is benign
2. **Test file errors**: Some test mocks are outdated but don't affect production build
3. **Offline Feed**: Sightings feed may show stale data when offline - expected behavior

---

## Post-Testing Actions

- [ ] Note any bugs discovered
- [ ] Update TODO.txt if issues found
- [ ] Prepare release notes for TestFlight
- [ ] Submit to external testers (if ready)

---

## TestFlight Release Notes (Draft)

**What's New in This Build:**

🆕 **Saved Places** - Save your home, work, and favorite locations. Get parking alerts customized to your spots!

🚗 **Tow Helper** - Vehicle towed? Don't panic! Step-by-step recovery guide with Milwaukee tow lot contacts, fee estimates, and direct call/directions buttons.

⚡ **Performance** - Faster app loading with offline support. Your data is cached locally for instant access.

📊 **Behind the Scenes** - Added analytics to help us improve the app and catch issues faster.

**Bug Fixes:**
- Fixed garbage schedule URL redirect issue
- Fixed theme card styling compatibility

---

*Checklist created: January 31, 2026*
*For: MKE CitySmart iOS TestFlight Build*
