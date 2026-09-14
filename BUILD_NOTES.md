# Build and verification notes

Verified on 2026-09-13 with Flutter 3.47.4 / Dart 3.13.3 on Windows and the Android 17 (API 37) emulator. Existing notification, localization, settings, and tracking work was reviewed before continuing it.

## Verification already performed

- `flutter test --reporter expanded`: 124 tests passed.
- `flutter test integration_test -d emulator-5554 --reporter expanded`: all 4 integration tests passed.
- `flutter analyze`: no issues found.
- `python -B tool/verify_source.py` and `python -B tool/smoke_platform_setup.py`: passed. Platform setup preserves existing iOS entitlements and is idempotent.
- `flutter build apk --release`: passed; `build/app/outputs/flutter-apk/app-release.apk` (55.8 MB).
- `flutter build appbundle --release`: passed; `build/app/outputs/bundle/release/app-release.aab` (54.2 MB).
- APK signature verification and AAB JAR signature verification passed. The APK contains ARM64, ARMv7, and x86-64 libraries, targets API 36, and includes notification, exact-alarm, and full-screen-intent permissions.
- Installed and launched the final optimized release APK on the emulator.

Google's command-line tools were missing from the local Android SDK, which prevented Flutter's App Bundle symbol verification. Installed commandlinetools-win-15859902 after checking its SHA-256 against the [official Android download page](https://developer.android.com/studio#command-line-tools-only); the normal bundle build then passed.

The existing Android release configuration signs with the Android debug certificate. These are verified development artifacts; configure the publishing/upload key before store release. Build output also reports existing `flutter_timezone` Kotlin migration and Cupertino font warnings.

## Notification verification

The device fixture is `tool/notification_device_probe.dart`. It uses the production app, database, notification service, router, and coordinator, with isolated probe prayer IDs/date and one-minute snoozes. It is a separate entry point and is not part of normal builds.

- Scheduled Isha displayed a high-importance alarm with a full-screen PendingIntent and both native action buttons.
- Rapid repeated Snooze actions consumed one snooze and scheduled one exact wake-up alarm.
- After terminating the test app process without force-stopping its alarms and locking the emulator, the scheduled Fajr snooze started a new process and opened Fajr. The reminder had the keep-screen-on flag, offered Mark as Prayed/Snooze, and blocked Back until a choice.
- The actual notification shade's Mark as Prayed action saved Fajr, cancelled the delivered alert, released the alarm state, and retained the success screen. Replayed actions preserved its first confirmation timestamp.
- A cold-start Mark as Prayed intent recorded Dhuhr and retained its success screen.
- Automated tests also cover malformed/dismissal payloads, buffered callbacks, delayed launch versus live responses, missing prayers, action errors, simultaneous confirmation/snooze, and retries.

Verification found and fixed three behavior issues: an immediate cold-start Snooze could duplicate the navigation shell during its entrance transition; Riverpod equality filtering suppressed later identical taps; native whole-second scheduling could fire before a fractional-second snooze deadline. The reminder route now enters without animation, notification events bypass state equality filtering, and trigger times round up to the next whole second.

Android full-screen access is declared, checked through `canUseFullScreenIntent`, and linked to its dedicated system settings from onboarding and settings. Permission status refreshes on resume. Lock-screen flags are applied only to valid prayer alarm intents and released on completion or safe exits. The alarm channel remains usable when full-screen access is denied; Android controls whether to launch full-screen or show a heads-up notification. See [Android's full-screen-intent limits](https://source.android.com/docs/core/permissions/fsi-limits).

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

## iOS release prerequisite

Native iOS app shielding depends on Apple's Family Controls entitlement and a Device Activity Monitor Extension target. The source and entitlement templates are included under `native/ios/`, but Apple Developer approval, signing and attaching the extension target must be done in Xcode with the developer account that will publish the app.

## Android Prayer Focus

Android intentionally ships the fail-safe in-app Prayer Focus mode rather than an Accessibility/overlay-based blocker. This is a product and store-safety decision, not an unfinished placeholder.
