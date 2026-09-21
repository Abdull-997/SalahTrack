# SalahTrack store privacy checklist

Audit date: 21 September 2026

This checklist is derived from the final repository source. It is preparation
for manual App Store Connect and Google Play Console entry, not a record that
either form was submitted and not legal advice.

## Source-of-truth implementation

- No SalahTrack account, backend, cloud sync, remote push, analytics,
  crash-reporting, advertising, attribution, or tracking SDK is present.
- Prayer and Ramadan history remains in the local SQLite database. Preferences
  remain in local SharedPreferences. Neither is uploaded by the app.
- Automatic foreground location is optional. Background/Always location is not
  requested.
- Prayer-calendar requests send latitude, longitude, year, month, calculation
  method, Asr school, and high-latitude adjustment by HTTPS to
  `api.aladhan.com`.
- Manual city autocomplete sends the typed search text, selected ISO country
  code, result limit/layers, and app language by HTTPS to
  `photon.komoot.io`, using OpenStreetMap data. Native OS geocoding is a
  fallback and may process place queries or coordinates.
- Network services necessarily receive ordinary connection metadata such as an
  IP address. The app does not add an account, advertising, or device ID.
- Report a Problem prepares category, description, reproduction steps, app
  version/build, platform, OS version, device model, and app language locally.
  The user reviews it and must press Send in their own email app. No GPS,
  prayer/Ramadan history, religious activity, or device identifier is silently
  attached. If sent, email providers and the support mailbox receive the
  visible report and normal email metadata.
- The system App Store/Google Play review prompt may contact the applicable
  store only after the locally controlled eligibility flow.

## Data inventory

| Data | Local use/storage | Off-device recipient | Required/optional |
| --- | --- | --- | --- |
| Automatic precise/approximate location | Current foreground position; selected coordinates/city/country/time zone saved in preferences | AlAdhan receives coordinates; native geocoder may receive coordinates | Optional; manual city is available |
| Manual city search | Search results and selected coordinates; selection saved in preferences | Photon receives query, country code and language; native geocoder may receive query/coordinates; AlAdhan later receives selected coordinates | Required only if manual location is chosen |
| Prayer calculation fields | Preferences/cache | AlAdhan receives year, month, method, Asr school and high-latitude rule | App functionality |
| Prayer schedule and Hijri metadata | SQLite cache | Received from AlAdhan; not uploaded as user history | App functionality |
| Prayer status/history | SQLite; can reveal religious practice | None found | Local-only |
| Ramadan fasting, Tarawih, Qiyam and goals | SQLite; can reveal religious practice | None found | Local-only |
| Compass heading | Live Qibla display | None found | Local-only, transient |
| Local notification schedules/actions | OS/plugin pending-notification storage | No remote push service | Optional permission |
| Report text and displayed technical information | Prepared transiently for review | User's email provider and support mailbox only if user sends | Optional, user initiated |
| Device model/OS/app version/language | Displayed in problem-report review | Included only if the user sends that report | Optional, user initiated |
| IP/connection metadata | Not deliberately stored by SalahTrack | Network and contacted service providers | Inherent in network requests |

## Apple App Privacy — manual answers to verify and enter

1. Declare location used for **App Functionality**, not tracking and not linked
   to a SalahTrack account. The source can transmit coordinates to AlAdhan and
   native geocoding. Confirm in App Store Connect whether both **Precise
   Location** and **Coarse Location** should be selected for the released
   permission behavior.
2. Do not describe local prayer/Ramadan history as collected by the developer:
   source review found no off-device transmission. Reconfirm this after every
   dependency or endpoint change.
3. The optional support email may contain user-entered content and the visible
   device/app fields. Check the current App Store Connect rule for data supplied
   in optional customer-support requests before deciding whether **Other User
   Content**, **Device Information**, or **Diagnostics** must be disclosed. Do
   not characterize it as automatic collection.
4. Select **Data Used to Track You: No**. No tracking, advertising, ATT prompt,
   or cross-app identifier is present.
5. Do not select contacts, photos, audio, health, purchases, financial,
   advertising ID, user ID, or crash/performance analytics based on this source.
6. Enter the published policy URL:
   `https://abalh101.github.io/salahtrack-privacy/index.html` after uploading
   and validating the generated site.
7. In an Xcode 26 archive, inspect the generated privacy report and merged
   `PrivacyInfo.xcprivacy` entries from plugins before submitting. This cannot
   be proven on Windows.

## Google Play Data Safety — manual answers to verify and enter

1. Disclose location transmitted for **App functionality**. Automatic precise
   access is optional because manual city selection exists. Manual city-level
   location is part of the core setup path.
2. Include Photon/manual search and AlAdhan when assessing whether location is
   **collected** and/or **shared**. Do not claim ephemeral processing unless the
   providers' current retention and service-provider terms prove it.
3. Data sent directly by the user through an external email composer is
   optional and user initiated. Check the current Play Data Safety
   user-initiated/customer-support exception, then answer consistently with the
   report preview and policy. The app itself does not send the email.
4. Local prayer/Ramadan history, compass heading, notification actions, and
   local preferences are not transmitted and therefore are not collected by
   the app under the audited implementation.
5. Data in the app's explicit API requests is encrypted in transit with HTTPS.
   Native OS geocoding transport/provider behavior must be confirmed on final
   Android devices before answering that every collected-data path is encrypted.
6. **Advertising/analytics/tracking: No**. No corresponding SDK or permission
   was found.
7. There is no account creation. Local app data can be removed through Android
   clear-storage/uninstall; there is no in-app remote deletion request because
   SalahTrack has no developer-hosted user record. Answer the Console's exact
   deletion questions according to their current wording.

## Third-party/provider verification still required

- Confirm current AlAdhan terms, operator role, retention, deletion process,
  and international-transfer position. Source proves the fields sent, not the
  provider's retention.
- Confirm current Photon service terms and retention and the applicable
  OpenStreetMap attribution requirements.
- Confirm which native geocoding provider/services are used on each final iOS
  and Android device configuration.
- Confirm the selected email app/provider only when a user chooses to send a
  report; SalahTrack cannot determine or control the user's provider.
- Review final signed/merged Android and iOS artifacts for any permission,
  entitlement, privacy manifest, or SDK not visible in the repository audit.

## Console actions not performed

- No Apple App Privacy answer was submitted.
- No Google Play Data Safety answer or special-permission declaration was
  submitted.
- No developer-account, certificate, signing, or provisioning setting was
  changed.
