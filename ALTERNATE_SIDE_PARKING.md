# Alternate-Side Parking Module

This module provides an end-to-end alternate-side parking experience: core algorithm, reminders, UI widgets, and a full screen.

## Core Rules
- Odd calendar days → park on odd-numbered addresses.
- Even calendar days → park on even-numbered addresses.
- Side flips automatically at midnight (local time).
- “Switch soon” warning appears when the flip is within 2 hours.

## Features
- **Service** (`lib/services/alternate_side_parking_service.dart`)
  - Determines the correct side by date.
  - Computes next switch time (midnight) and “switch soon” flag.
  - Validates if the vehicle/address number matches the required side.
  - Builds notification messages for morning, evening, and midnight (3 priority levels).
  - Generates 14-day schedules with today/tomorrow helpers.
- **Dashboard Card** (`lib/widgets/alternate_side_parking_card.dart`)
  - Compact summary with color badge (orange=odd, blue=even), next switch time, and placement guidance.
- **Full Screen** (`lib/screens/alternate_side_parking_screen.dart`)
  - Today/tomorrow status, 14-day schedule, how-it-works, and notification toggles (UI).
- **Tests** (`test/alternate_side_parking_service_test.dart`)
  - 14 cases covering odd/even logic, midnight switch, schedule generation, leap year/month rollovers, correctness validation, and notification priorities.

## Navigation
- Dashboard tile: “Alternate-side parking” links to `/alternate-parking`.
- Route registered in `lib/main.dart`.

## Colors
- Orange for odd days, Blue for even days.
- Inherits global theme (Material 3, Inter) from `CSTheme`.

## Extending
- Wire the notification toggles to your push scheduling service.
- If you have per-city rules, inject overrides into the service where needed.
