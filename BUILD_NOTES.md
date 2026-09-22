# Build and verification notes

## Current release audit (2026-09-20)

- `flutter clean`, `flutter pub get`, `flutter analyze` and `flutter test` completed; analysis found no issues and 289 tests passed.
- The release AAB and APK built with `PRIVACY_POLICY_URL=https://abalh101.github.io/privacy-policy-salah/`. The merged APK targets API 36, and `zipalign -c -P 16 -v 4` passed. The 64-bit ELF libraries have at least 16 KB LOAD alignment.
- No `android/key.properties` exists in this checkout. The current AAB and APK are **unsigned verification artifacts** and cannot be uploaded or installed as release builds. The signature results below describe an older signed build, not these artifacts.
- The Android API 37 emulator startup test passed. The onboarding location page now waits for an explicit tap after its data-flow disclosure before requesting location. Prayer alerts use normal high-importance notifications.

## Historical verification (2026-09-13)

Verified on 2026-09-13 with Flutter 3.47.4 / Dart 3.13.3 on Windows and the Android 17 (API 37) emulator. Existing notification, localization, settings, and tracking work was reviewed before continuing it.

### Verification performed then

- `flutter test --reporter expanded`: 124 tests passed.
- `flutter test integration_test -d emulator-5554 --reporter expanded`: all 4 integration tests passed.
- `flutter analyze`: no issues found.
- `python -B tool/verify_source.py` and `python -B tool/smoke_platform_setup.py`: passed. Platform setup preserves existing iOS entitlements and is idempotent.
- `flutter build apk --release`: passed; `build/app/outputs/flutter-apk/app-release.apk` (55.8 MB).
- `flutter build appbundle --release`: passed; `build/app/outputs/bundle/release/app-release.aab` (54.2 MB).
- APK signature verification and AAB JAR signature verification passed for the earlier validation fixture. The APK contains ARM64, ARMv7, and x86-64 libraries, targets API 36, and includes notification and exact-alarm permissions.
- Installed and launched the final optimized release APK on the emulator.

Google's command-line tools were missing from the local Android SDK, which prevented Flutter's App Bundle symbol verification. Installed commandlinetools-win-15859902 after checking its SHA-256 against the [official Android download page](https://developer.android.com/studio#command-line-tools-only); the normal bundle build then passed.

The Android release configuration never falls back to the Android debug certificate. It reads publishing credentials from the ignored `android/key.properties` file; without that file, generated release artifacts are unsigned verification builds and cannot be uploaded. Build output also reports existing `flutter_timezone` Kotlin migration and Cupertino font warnings.

## Notification verification

The device fixture is `tool/notification_device_probe.dart`. It uses the production app, database, notification service, router, and coordinator, with isolated probe prayer IDs/date and one-minute snoozes. It is a separate entry point and is not part of normal builds.

- Scheduled Isha displayed a high-importance standard notification with both native action buttons.
- Rapid repeated Snooze actions consumed one snooze and scheduled one exact wake-up alarm.
- After terminating the test app process, the scheduled Fajr snooze remained available through Android's normal notification surface and opened SalahTrack only after user interaction.
- The notification shade's Mark as Prayed action saved Fajr, cancelled the delivered alert, and retained the success screen. Replayed actions preserved its first confirmation timestamp.
- A cold-start Mark as Prayed intent recorded Dhuhr and retained its success screen.
- Automated tests also cover malformed/dismissal payloads, buffered callbacks, delayed launch versus live responses, missing prayers, action errors, simultaneous confirmation/snooze, and retries.

Verification found and fixed three behavior issues: an immediate cold-start Snooze could duplicate the navigation shell during its entrance transition; Riverpod equality filtering suppressed later identical taps; native whole-second scheduling could fire before a fractional-second snooze deadline. The reminder route now enters without animation, notification events bypass state equality filtering, and trigger times round up to the next whole second.

Android reminders use the high-importance `salahtrack_prayer_reminders_v1` channel with notification audio/vibration governed by Android and the user's channel settings. They can appear on the lock screen and in the notification shade under normal OS policy, but never launch an Activity automatically over another app. Initial prayer alerts are dismissible; actionable grace and snooze reminders may be ongoing until handled. Exact alarms retain an inexact idle-safe fallback when exact scheduling is unavailable.

iOS source/configuration and Flutter tests confirm Time Sensitive interruption levels, localized notification categories with foreground Mark as Prayed/Snooze actions, notification delegate forwarding, implicit-engine plugin registration, and the Time Sensitive entitlement in all three Runner build configurations. The AppDelegate follows [Flutter's UIScene registration guidance](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate). An iOS native build, signing, and physical-device delivery check require macOS/Xcode and were not run on this Windows machine. Verify delivery with Time Sensitive enabled/disabled and Focus enabled on an iPhone before release.

## Reproducing platform setup

Run either bootstrap script. It generates the Flutter platform templates, patches them, resolves dependencies and then runs analyzer/tests automatically.

macOS/Linux:

```bash
chmod +x tool/bootstrap.sh
./tool/bootstrap.sh
```

Windows PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
./tool/bootstrap.ps1
```

Continue physical-device checks before publishing:

```bash
flutter run
flutter test integration_test
flutter build appbundle --release
# macOS only, after Apple signing/entitlements:
flutter build ipa --release
```

## iOS Prayer Focus scope

The current iOS target has no Family Controls entitlement, App Group, Device
Activity extension, or FamilyControls/ManagedSettings/DeviceActivity source.
It ships the safe in-app Prayer Focus fallback. Any future native shielding must
be implemented and privacy-audited as a separate release and requires Apple's
approval before distribution.

## Android Prayer Focus

Android intentionally ships the fail-safe in-app Prayer Focus mode rather than an Accessibility/overlay-based blocker. This is a product and store-safety decision, not an unfinished placeholder.
