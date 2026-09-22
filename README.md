# SalahTrack

**Prayer Tracker & Reminders**

SalahTrack lets you log the five daily prayers, track which were prayed or missed, and receive reminders at prayer time and again if a prayer has not been confirmed. It also includes Qibla and an optional Prayer Focus mode.

The app is intentionally **not** a religious authority and does not shame or judge the user. Focus restrictions are voluntary and always fail open.

## MVP included

- iOS + Android Flutter application architecture
- 7-step onboarding
- GPS location or manual city/country selection
- AlAdhan monthly prayer-time provider behind a provider interface
- local SQLite cache for prayer days/history
- five daily prayers: Fajr, Dhuhr, Asr, Maghrib, Isha
- calculation method, Asr school, high-latitude rule and per-prayer minute offsets
- correct IANA timezone/DST handling
- next-prayer countdown and daily prayer status
- local prayer-time, grace-period and snooze notifications
- Android exact-alarm permission fallback
- Prayer state machine: upcoming → active → pending → prayed/snoozed/skipped/missed
- configurable grace period, snooze duration and snooze limit
- configurable confirmation text
- safe Emergency Unlock with a per-prayer bypass
- tracker: today, current week and current month
- automatic, opt-out Ramadan mode based on the cached Hijri calendar
- Suhur/Fajr and Iftar/Maghrib times with live countdowns
- separate fasting, Tarawih, Qiyam and simple daily-goal tracking
- configurable action-free Suhur and Iftar reminders
- one-time, platform-native review request eligibility after 72 hours
- Qibla bearing + compass fallback
- light/dark/system theme
- German, English and Arabic/RTL UI architecture
- notification deep links into Prayer Focus
- Android safe Basic Prayer Focus fallback
- iOS Time Sensitive local notifications
- unit and integration tests

Features explicitly described as later phases in the product specification (Quran, Adhkar library, mosque search, accounts/cloud sync, Watch/Wear OS, family mode and native Home Screen widgets) are not bundled into this first release branch.

## Required toolchain

Recommended baseline:

- Flutter **3.47.0+**
- Dart **3.13.0+** (bundled with Flutter 3.47)
- Android Studio with Android SDK API 36
- Java 17+
- Xcode **26+** with the iOS **26 SDK** for App Store builds
- Swift Package Manager (Flutter plugin integration; CocoaPods is not required
  by the checked-in project)

Check your environment:

```bash
flutter doctor -v
```

## First-time setup

The production Android and iOS projects are checked in. The setup command
updates SalahTrack's known native settings in place; it does not regenerate or
replace either platform project.

### macOS / Linux

```bash
chmod +x tool/bootstrap.sh
./tool/bootstrap.sh
```

### Windows PowerShell

```powershell
Set-ExecutionPolicy -Scope Process Bypass
./tool/bootstrap.ps1
```

The bootstrap script:

1. applies the checked-in SalahTrack Android/iOS native settings,
2. configures scheduled-notification receivers and permissions,
3. enables Android core-library desugaring,
4. configures the iOS location usage description,
5. runs `flutter pub get`,
6. runs `flutter analyze`,
7. runs `flutter test`.

Then start the app:

```bash
flutter run
```

## Manual Flutter commands

After bootstrapping:

```bash
flutter pub get
flutter analyze
flutter test
flutter test integration_test
```

Release builds:

```bash
flutter build appbundle --release
flutter build ipa --release
```

Signing still has to be configured with your own Google Play / Apple Developer credentials.

Android reads publishing credentials only from the ignored
`android/key.properties` file. Without that file, release bundles are built
unsigned for verification; the build never falls back to Flutter's debug key.
Use the standard properties `storeFile`, `storePassword`, `keyAlias`, and
`keyPassword`, with `storeFile` relative to `android/app`.


### Source-only verification

If Flutter is not installed yet, the repository still includes a lightweight, dependency-free Python static verifier that checks required source files, package imports, localization-key parity and unsafe Android permission regressions:

```bash
python3 tool/verify_source.py
python3 tool/smoke_platform_setup.py
```

This is not a replacement for `flutter analyze` or `flutter test`; compiler-level verification requires the Flutter SDK.

## Android setup

`tool/apply_platform_setup.py` adds only the permissions the current MVP needs:

- `INTERNET`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_FINE_LOCATION`
- `POST_NOTIFICATIONS`
- `RECEIVE_BOOT_COMPLETED`
- `VIBRATE`
- `SCHEDULE_EXACT_ALARM`

The app deliberately does **not** request:

- `QUERY_ALL_PACKAGES`
- `SYSTEM_ALERT_WINDOW`
- background location
- an Accessibility Service
- device-owner privileges

### Exact alarms

Prayer notifications use exact scheduling only when Android reports that the app can schedule exact alarms. Otherwise SalahTrack automatically uses an inexact idle-safe notification mode.

Android vendors can still apply additional background/battery restrictions to scheduled work. The release checklist therefore requires physical-device testing on Samsung, Pixel and at least one aggressively managed Android skin such as Xiaomi; SalahTrack does not attempt to bypass OEM power-management policies.

The user can request precise-alarm permission from Onboarding or Settings. A denied permission must never crash the app.

Prayer reminders use the high-importance `salahtrack_prayer_reminders_v1`
channel and the normal Android notification system. Initial prayer alerts are
dismissible; actionable grace and snooze reminders may stay ongoing until the
user responds. Tapping a reminder opens SalahTrack. The application does not
request overlay, accessibility, usage-access, background-location, or other
permissions intended to force its interface over another application.

### Android Prayer Focus

A normal consumer Android app cannot safely suspend arbitrary third-party apps through a general public app-blocking API. SalahTrack therefore does **not** disguise an Accessibility Service or overlay as an app blocker.

Android MVP behavior:

- Prayer Focus screen inside SalahTrack
- persistent prayer/focus state
- notifications after grace/snooze
- confirmation, snooze and skip
- Emergency Unlock
- no lock-out of Phone, Maps, emergency or system functionality

The Kotlin platform bridge explicitly reports system-level app shielding as unavailable. This is intentional.

## iOS setup

The current iOS app delegate is in:

```text
ios/Runner/AppDelegate.swift
```

The release target currently uses local notifications, including Apple's Time
Sensitive notification entitlement. It does **not** include FamilyControls,
ManagedSettings, DeviceActivity, an App Group, a Device Activity extension, or
the Family Controls entitlement. Accordingly, the current release does not
inspect Screen Time selections or usage data and provides only the in-app Basic
Prayer Focus behavior.

Family Controls must be treated as a future feature: it requires new source and
extension targets, Apple entitlement approval, an updated privacy audit and
policy, and physical-device release testing before it can be enabled.

## Prayer-time API

The MVP uses the AlAdhan calendar endpoint through the abstraction:

```text
PrayerTimesProvider
└── AlAdhanPrayerTimesProvider
```

No API key is hardcoded or required for this provider.

The app requests a monthly calendar, converts the provider's local prayer times using the returned IANA timezone and caches prayer entries locally. Every cached month is bound to a source profile containing location, calculation method, Madhhab, high-latitude rule, minute adjustments and grace period, so stale data from another city or configuration is not silently reused. Month boundaries are repaired when adjacent months are cached so the final Isha tracking window ends at the following Fajr. The UI reads from the repository instead of directly from the network.

Failure behavior:

1. try network refresh,
2. use the cached month if refresh fails,
3. use today's cached data if present,
4. show a clear error if no reliable cache exists,
5. never fabricate `00:00` prayer times.

## Local data

SQLite (`sqflite`) stores:

- prayer entries/history
- cached prayer schedules
- prayer-day metadata and timezone
- Hijri display value from the prayer provider
- focus sessions
- Emergency Unlock bypass state
- fasting, Tarawih and Qiyam records by Ramadan day
- Ramadan goals and their daily completion history

Small user preferences are stored locally with SharedPreferences:

- location selection
- calculation settings
- grace/snooze settings
- theme/language
- onboarding status
- Ramadan feature and reminder preferences
- first-launch and one-time review-request state

No account is required.

## Project structure

```text
lib/
├── app/
│   ├── localization/
│   └── router/
├── core/
│   ├── api/
│   ├── database/
│   ├── errors/
│   ├── location/
│   ├── notifications/
│   ├── theme/
│   └── time/
├── features/
│   ├── onboarding/
│   ├── prayer_focus/
│   ├── prayer_times/
│   ├── prayer_tracker/
│   ├── qibla/
│   └── settings/
└── shared/
```

Business logic does not depend on widgets. Prayer Focus is behind `PrayerFocusService`, and prayer-time providers are interchangeable.

## State machine

```text
UPCOMING
   │ prayer begins
   ▼
ACTIVE
   │ grace expires
   ▼
PENDING ───────► PRAYED
   │
   ├───────────► SKIPPED
   │
   └───────────► SNOOZED
                    │ snooze expires
                    ▼
                 PENDING

ACTIVE / PENDING / SNOOZED
            │ tracking window ends
            ▼
          MISSED
```

`MISSED` is presented to the user as **not confirmed**, not as a religious ruling.

## Tests

Current tests include:

```text
test/features/prayer_times/prayer_state_machine_test.dart
test/features/prayer_times/prayer_cache_key_test.dart
test/core/timezone_service_test.dart
test/core/prayer_notification_planner_test.dart
test/features/settings/prayer_settings_test.dart
test/features/prayer_focus/prayer_focus_policy_test.dart
test/features/qibla/qibla_calculator_test.dart
integration_test/app_smoke_test.dart
integration_test/prayer_flow_test.dart
```

Run:

```bash
flutter test
flutter test integration_test
```

## Privacy

See [PRIVACY.md](PRIVACY.md).

Design principles:

- local first
- no advertising SDK
- no prayer-behavior analytics
- no public ranking
- no account requirement
- no sale of data
- no permanent background GPS

## Release checklist

Before publishing:

- run `flutter analyze`
- run all unit/integration tests on real Android and iPhone devices
- verify prayer times against local mosque expectations for supported methods
- test Berlin DST transitions and at least one non-European timezone
- test offline launch with an existing monthly cache
- test denied location and notification permissions
- test Android exact-alarm denied/allowed states
- test Android reboot rescheduling
- verify iOS Basic Prayer Focus fails open and does not request Screen Time access
- test Emergency Unlock repeatedly
- test Arabic RTL and large text / VoiceOver / TalkBack
- configure Android release signing
- configure Apple signing and verify only the intended Time Sensitive entitlement
- prepare App Store privacy details and Google Play Data Safety declaration
- only add licensed Adhan audio if audio is enabled in a later release

## Product safety rule

If any platform-specific Prayer Focus operation fails, SalahTrack **fails open**. It must never leave a person permanently unable to use their device.
