# Hosting the SalahTrack privacy policy

The in-app privacy policy and legal notice are sourced from
`lib/app/legal/legal_documents.dart`. Do not maintain a separate hand-written
copy for the website.

Generate static, localized HTML from that same source:

```text
dart run tool/export_legal_documents.dart privacy_site_update
```

The output includes an English root page, separate policy/legal pages, shared
responsive light/dark styling, and a complete RTL-aware folder for every
supported app language. The current canonical in-app URL is:

```text
https://abalh101.github.io/salahtrack-privacy/index.html
```

It is the default value in `PrivacyLegalConfig`. For a future domain change,
either update that default or override it in both release builds:

```text
flutter build appbundle --dart-define=PRIVACY_POLICY_URL=https://NEW-REAL-DOMAIN/PATH/
flutter build ipa --dart-define=PRIVACY_POLICY_URL=https://NEW-REAL-DOMAIN/PATH/
```

The app accepts and shows only a valid `https://` value. Regenerate and publish
the files whenever the legal source changes, verify every language, and enter
the canonical URL in App Store Connect and Google Play Console.
