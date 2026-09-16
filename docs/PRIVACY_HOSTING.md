# Hosting the SalahFocus privacy policy

The in-app privacy policy and legal notice are sourced from
`lib/app/legal/legal_documents.dart`. Do not maintain a separate hand-written
copy for the website.

Generate static, localized HTML from that same source:

```text
dart run tool/export_legal_documents.dart build/legal_site
```

The output includes English root files and one folder for every supported app
language. The current canonical in-app URL is:

```text
https://abalh101.github.io/privacy-policy-salah/
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
