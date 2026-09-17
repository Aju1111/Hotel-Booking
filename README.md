# Hotel Booking App

Flutter app for the Raintech Hotel coding assessment, extended with a mobile-first
front-desk UI (dashboard, check-in, check-out, rooms, reports, profile).

**Core assessment screen:** open the app → **Booking** tab (`/booking`).

---

## How to Run

**Requirements:** Flutter SDK 3.12+ ([install Flutter](https://docs.flutter.dev/get-started/install))

```bash
flutter pub get
flutter run
```

Run on a specific device:

```bash
flutter devices
flutter run -d chrome          # web
flutter run -d <device-id>     # Android / iOS emulator or connected phone
```

Run tests:

```bash
flutter test
flutter test test/booking_calculator_test.dart test/room_booking_assessment_test.dart
```

> Windows desktop (`flutter run -d windows`) needs Visual Studio with the
> “Desktop development with C++” workload.

---

## Stack / Framework

| Layer | Choice |
|---|---|
| **Framework** | **Flutter** (Dart 3.12+) |
| **Routing** | `go_router` — shell layout with bottom navigation |
| **State** | `StatefulWidget` (no Redux / Bloc / Riverpod) |
| **Data** | Hardcoded sample data in `lib/data/sample_data.dart` — no backend or database |
| **Formatting** | `intl` for dates and currency |
| **Tests** | `flutter_test` — unit tests for booking logic + widget/layout tests |

Booking logic is separated from UI in `lib/utils/booking_calculator.dart`.

---

## Core Assessment (Room Booking)

Implemented on **Room Booking** (`lib/screens/room_booking_screen.dart`):

- Room list (R101–R301) with photos, types, prices, and max guests
- Check-in / check-out date pickers
- Single room selection (optional extra rooms for the same stay)
- Nights and total price (`nights × price per night`)
- Validation with clear messages:
  - Check-out must be after check-in
  - Check-in cannot be in the past
  - Room required; overlapping bookings blocked
- **Bonus:** guest-count filter, hardcoded existing bookings, unit tests in `test/booking_calculator_test.dart`

---

## Improvements With More Time

- **Persistence** — save bookings to local storage or a real API instead of in-memory session state
- **Form validation** — field-level errors on check-in / check-out forms
- **Accessibility** — semantic labels, larger tap targets audit, screen-reader pass
- **Auth** — real sign-in for staff roles (front desk vs housekeeping)
- **Payments & invoices** — PDF receipts and registration cards
- **More tests** — integration tests for full booking and check-out flows; golden tests for UI components
- **Offline / sync** — queue front-desk actions when connectivity is poor

---

## Project Layout (brief)

```
lib/
├── screens/room_booking_screen.dart   # coding test main screen
├── utils/booking_calculator.dart      # nights, price, validation
├── data/sample_data.dart              # rooms & sample bookings
├── models/                            # HotelRoom, Booking, Guest
└── widgets/                           # RoomCard, RoomPhoto, shared UI kit
test/
├── booking_calculator_test.dart       # unit tests for calculation logic
└── room_booking_assessment_test.dart  # widget tests for coding requirements
```

Routes: `/` Dashboard · `/booking` · `/check-in` · `/check-out` · `/rooms` · `/reports` · `/profile`
