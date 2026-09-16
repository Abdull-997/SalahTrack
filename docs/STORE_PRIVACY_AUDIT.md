# SalahFocus store privacy audit

Audit date: 16 September 2026

Scope: Flutter/Dart source, `pubspec.yaml` and lockfile, Android manifests and
Kotlin code, iOS `Info.plist`, entitlements and Swift code, native templates,
and local persistence schemas. This is a technical audit, not legal advice.

## Executive summary

SalahFocus is local-first, but it is not fully offline. It has no accounts and
no SalahFocus backend. Prayer and Ramadan history stays in the app's SQLite
database. Precise coordinates and prayer calculation parameters leave the
device over HTTPS when the app requests a monthly calendar from
`api.aladhan.com`. Manual place searches and reverse geocoding may also leave
the device through the operating system's geocoding provider.

There are no analytics, crash-reporting, advertising, tracking, social-login,
or remote-push SDKs. No advertising identifier, vendor identifier, Android ID,
IMEI, contacts, photos, microphone, or user account data is accessed by the app
code.

## Data inventory and flow

| Data | Access/use | Storage | Off-device transfer |
| --- | --- | --- | --- |
| Precise or approximate location | Optional automatic location for prayer times and Qibla; a high-accuracy current position is requested after the user chooses the feature. While automatic mode is selected and the app process runs, a location stream uses a 1 km distance filter. | Latitude, longitude, city, country, time zone, and automatic/manual flag in SharedPreferences; coordinates also appear in the local prayer-cache source key. | Latitude/longitude is sent to AlAdhan for prayer calendars. Coordinates may be sent to the OS geocoder for a place label. |
| Manually entered city/country | Converts a place name into coordinates. | Entered labels and returned coordinates in SharedPreferences. | City/country is sent to the OS geocoding service; returned coordinates are later sent to AlAdhan. |
| Prayer calculation configuration | Calculation method, Asr school, high-latitude rule, date/month, manual offsets, grace/snooze and Friday settings. | SharedPreferences and SQLite source/cache fields. | AlAdhan receives coordinates, year/month, method, school, and high-latitude adjustment. Manual minute offsets, grace/snooze settings, Friday settings, and confirmation text are not in the API request. |
| Prayer schedule/cache | Five prayer times, sunrise, Gregorian/Hijri date, time zone and fetch/source metadata. | SQLite database `salah_focus.db`. | Downloaded from AlAdhan; cached values are not uploaded again as user data. |
| Prayer tracking/history | Upcoming/prayed/skipped/missed/snoozed state, confirmation/edit/snooze timestamps and snooze count. This can reveal religious practice. | SQLite `prayer_entries`. | No transmission found. It is not included in the prayer API request. |
| Ramadan activity | Fasting state, Tarawih/Qiyam completion, custom goal titles, archive/completion timestamps. This can reveal religious practice. | SQLite Ramadan tables. | No transmission found. |
| Preferences | Locale, theme, onboarding flag, prayer/Ramadan settings, custom confirmation text, first successful launch timestamp and whether a review request was attempted. | SharedPreferences. | No direct transmission found. Selected prayer calculation fields are separately sent for the prayer API request as described above. |
| Qibla/compass | Qibla bearing is calculated from stored coordinates; live compass heading rotates the display. | Compass heading is not persisted. | No transmission found. |
| Notifications | Local prayer, Friday, snooze, one-hour and Ramadan schedules; notification payloads contain schedule/prayer identifiers and actions. | Stored by the operating system/plugin as pending local notifications. | No remote push provider or push token is used. |
| Time zone and app version | Reads the device time-zone name and installed package version/build number. | Time zone is stored with location and prayer cache; version is display-only. | No transmission found by SalahFocus. |
| App review prompt | After the local eligibility delay, invokes the operating system's in-app review UI. | Only first-launch and attempted flags are stored locally. | Apple/Google store services may be contacted by the OS/plugin. SalahFocus does not receive review content. |

Normal HTTPS and geocoding requests expose connection metadata such as IP
address to network/service operators. The code does not add a device ID, user
ID, account ID, advertising ID, or custom analytics header.

## Local storage and deletion

`SettingsRepository` uses SharedPreferences. `AppDatabase` uses SQLite and has
no automatic retention limit for prayer or Ramadan history. The current user
deletion mechanisms are the operating system's clear-app-data function and
uninstallation. Changing location/settings overwrites preferences and some
cached schedule data, but it is not a complete history deletion control.

No application-level encryption is implemented for the SQLite database or
SharedPreferences. They rely on the mobile operating system's app sandbox and
device protection. Because prayer history may reveal religious practice,
consider an in-app “Delete local data” action and assess whether stronger
at-rest protection is appropriate before release.

## Network services and SDK review

- `dio` is configured only for `https://api.aladhan.com/v1`. The monthly
  calendar request sends coordinates and calculation parameters.
- `geocoding` uses Android/iOS platform geocoding. Depending on platform and
  device configuration, Apple, Google, or another system provider may process
  the place query or coordinates.
- `geolocator`, `flutter_compass`, `flutter_timezone`, `sqflite`,
  `shared_preferences`, and `package_info_plus` provide device/local features;
  no independent analytics or advertising call was found.
- `flutter_local_notifications` schedules local notifications. There is no
  Firebase Messaging, APNs token handling, or SalahFocus notification server.
- `in_app_review` invokes StoreKit/Google Play review UI. It does not add
  SalahFocus analytics, but the app store service can receive its normal store
  interaction data.
- No Firebase, Crashlytics, Sentry, Google Mobile Ads, Meta, AppsFlyer,
  Adjust, Amplitude, Mixpanel, or similar SDK is present in the lockfile.

AlAdhan's public site identifies its API and operator, but the audit did not
find a clear public API privacy/retention commitment. Do not promise a specific
AlAdhan retention period until this has been confirmed contractually or in a
published policy.

## iOS privacy-relevant configuration

Current Runner configuration:

- `NSLocationWhenInUseUsageDescription`: precise/while-in-use location.
- `com.apple.developer.usernotifications.time-sensitive`: Time Sensitive local
  notifications.
- Runtime alert/badge/sound notification authorization through
  `flutter_local_notifications`.
- No `NSLocationAlwaysAndWhenInUseUsageDescription`, no location
  `UIBackgroundModes`, no App Tracking Transparency key, and no HealthKit,
  contacts, photos, camera, microphone, Bluetooth, or motion purpose string.
- No Family Controls entitlement, App Group entitlement, Device Activity
  extension, FamilyControls/ManagedSettings/DeviceActivity imports, or Screen
  Time bridge exists in the current app/native source. The previous README
  description was stale and is not evidence of built functionality.

The app target does not currently contain its own `PrivacyInfo.xcprivacy`.
Several included iOS plugins do ship privacy manifests (including
`shared_preferences_foundation`, `sqflite_darwin`, `geolocator_apple`,
`geocoding_ios`, `flutter_local_notifications`, `flutter_timezone`,
`package_info_plus`, and `in_app_review`). Verify the merged privacy report in
an Xcode release archive before submission; this cannot be validated on the
current Windows machine.

## Android privacy-relevant permissions

The release manifest declares:

- `INTERNET`: AlAdhan and platform network-backed geocoding.
- `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION`: optional automatic
  location.
- `POST_NOTIFICATIONS`: runtime notification permission on supported Android.
- `RECEIVE_BOOT_COMPLETED`: restore scheduled local notifications after reboot
  or app replacement.
- `VIBRATE`: notification vibration.
- `SCHEDULE_EXACT_ALARM`: prayer reminders at exact times where permitted.
- `USE_FULL_SCREEN_INTENT`: optional prayer alarm display on the lock screen.

There is no `ACCESS_BACKGROUND_LOCATION`, foreground-location service,
advertising ID permission, contacts/storage/media permission, usage-stats
permission, Accessibility Service, overlay, VPN, or account permission.

## Likely Apple App Privacy answers

Apple defines “collect” based on off-device transmission that a developer or
third party can access beyond what is necessary to service a real-time request.
Because exact coordinates are sent to AlAdhan and platform geocoding, provider
retention must be confirmed before choosing the final answer.

Conservative submission recommendation until that confirmation exists:

- Declare **Precise Location** as collected for **App Functionality**, optional,
  not used for tracking, and not linked to a SalahFocus account (there is no
  account). Confirm whether Apple expects Coarse Location as well for users who
  grant approximate access.
- Do not declare locally stored prayer/Ramadan history as collected by the
  developer under Apple's off-device definition; it never leaves the device in
  the current code.
- Do not declare identifiers, contact information, diagnostics, usage analytics,
  purchases, contacts, photos, audio, or advertising data based on current code.
- If AlAdhan or a geocoding provider retains location or request metadata,
  include that third-party practice. Do not select “Data Not Collected” without
  resolving this uncertainty.
- The App Store privacy policy URL is mandatory. Use the configured public
  HTTPS URL generated from the same legal source as the in-app policy.

Apple references:

- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/app-store/review/guidelines/#privacy

## Likely Google Play Data Safety answers

Google defines collection as transmitting user data off-device, including via
libraries/SDKs. Therefore the form must include the location transmission even
if a provider claims to process it ephemerally.

Conservative submission recommendation:

- **Precise location**: collected, optional, for **App functionality**. Mark
  ephemeral only if AlAdhan and the applicable platform geocoder actually meet
  Google's real-time/in-memory standard. Otherwise mark it non-ephemeral.
- **Approximate location**: also declare if the released app accepts Android
  approximate permission or geocoding city-level data is transmitted.
- Whether transfer to AlAdhan/geocoding is “shared” depends on whether the
  provider qualifies as a service provider under Google's definition or the
  user-initiated/prominent-disclosure exception. Verify terms before answering.
- Locally processed prayer/Ramadan history, preferences, compass heading, and
  notification actions are not collected for Data Safety because they are not
  transmitted off-device.
- No advertising, analytics, crash data, account data, device IDs, or installed
  apps should be declared based on current code.
- Data in transit for the app's own prayer API call is encrypted with HTTPS.
  Confirm the geocoding transport on each release platform before answering
  that *all* collected data is encrypted in transit.
- The app does not currently provide an in-app deletion request/action. Users
  can clear app data or uninstall. Answer the deletion-mechanism question only
  after checking the exact Play Console wording and any release changes.

Google reference:

- https://support.google.com/googleplay/android-developer/answer/10787469

## Issues to resolve before public release

1. Supply a complete service/postal street address if required for the German
   Impressum. Only “Düsseldorf, Germany” was provided, so the app deliberately
   does not invent the missing address.
2. Publish the generated privacy policy at a real public HTTPS URL and set
   `PRIVACY_POLICY_URL` in both store release builds.
3. Confirm AlAdhan's operator, legal role, location/log retention, deletion
   process, and GDPR transfer safeguards. Do the same for the platform
   geocoding path used in the final Android/iOS builds.
4. Add a concise disclosure before the first location request stating that
   coordinates are sent to AlAdhan and may be processed by platform geocoding,
   then verify consent/legal-basis wording for the target markets.
5. Consider an in-app local-data deletion control and a retention choice for
   sensitive prayer/Ramadan history.
6. Verify the merged iOS privacy manifest report and signed entitlements in an
   Xcode archive on macOS. Verify the final merged Android manifest/AAB in Play
   Console.
7. Re-audit the store forms, policy, and hosted export whenever dependencies,
   permissions, network endpoints, or data flows change.
