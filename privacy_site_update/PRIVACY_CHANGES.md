# SalahTrack privacy website changes

Audit date: 21 September 2026

The live site at
`https://abalh101.github.io/salahtrack-privacy/index.html` was inspected after
the final application-source audit. The website repository is not part of the
current workspace, so the live site was not modified. This directory is ready
to copy to the root of the `salahtrack-privacy` GitHub Pages repository.

## Inaccuracies found on the live site

- All 13 language URLs responded successfully and contained translated policy
  bodies, the current SalahTrack name, the support email, and the supplied
  German provider address.
- The live geocoding section referred only generally to platform/system
  providers. The final app first sends manual city autocomplete queries to
  Photon at `photon.komoot.io`, which uses OpenStreetMap data, and uses native
  platform geocoding as a fallback. Photon was not named on any inspected live
  language page.
- The live Punjabi page uses Gurmukhi and `dir="ltr"`, while the app's `pa`
  localization is Shahmukhi in Arabic script and uses RTL. The upload package
  now matches the actual app locale.
- The live policy already described AlAdhan, local religious records, the
  user-reviewed Report a Problem email flow, absence of analytics/tracking,
  the provider address, and light/dark responsive styling. Those accurate
  points were retained.

## Changes in this upload package

- Generated complete Privacy Policy and Legal Notice text for all app locales:
  `ar`, `bn`, `de`, `en`, `es`, `fa`, `fr`, `id`, `ms`, `pa`, `ps`, `tr`, and
  `ur`.
- Added the exact Photon/OpenStreetMap autocomplete disclosure: typed query,
  selected country code, app language, ordinary request metadata and IP
  address; native forward/reverse geocoding is described separately.
- Retained the exact AlAdhan fields proven by source: latitude, longitude,
  year, month, calculation method, Asr school and high-latitude rule.
- Clarified that Report a Problem is prepared locally, is reviewable/editable,
  is never sent automatically, and does not silently attach coordinates,
  prayer/Ramadan history, religious activity or device identifiers.
- Kept prayer and Ramadan tracking data described as sensitive and local-only.
- Set `lang` and `dir` on every page. Arabic, Farsi, Shahmukhi Punjabi, Pashto,
  and Urdu pages use semantic RTL.
- Added safe-area-aware mobile layout, logical CSS properties, dark/light mode,
  UTF-8 metadata, semantic headings, language links, and working `mailto:`
  contact links.
- Preserved the existing `privacy-xx.html` language routes and also supplied
  structured `xx/index.html`, `xx/privacy-policy.html`, and
  `xx/legal-notice.html` routes.
- Kept `SalahTrack` untranslated and removed no supported language.

## Corresponding final app behavior

- Photon flow: `lib/core/location/location_service.dart`
- AlAdhan request: prayer-times data provider under
  `lib/features/prayer_times/data/`
- Report preparation/email launch: settings problem-report domain/data code
- Local prayer/Ramadan persistence: SQLite repositories and app database
- Canonical translated legal source: `lib/app/legal/legal_documents.dart`
- Website generator: `tool/export_legal_documents.dart`

## Upload verification

After copying this directory into the website repository and publishing:

1. Open `index.html` and each `privacy-xx.html` URL on mobile and desktop.
2. Confirm every language selector link returns HTTP 200.
3. Confirm `ar`, `fa`, `pa`, `ps`, and `ur` have `dir="rtl"`.
4. Search the published output for `SalahFocus` and confirm there are no hits.
5. Confirm `Photon`, `OpenStreetMap`, `api.aladhan.com`, the provider address,
   and `mailto:ar830222@gmail.com` appear as intended.
6. Validate the HTML and test light/dark mode and keyboard navigation.
