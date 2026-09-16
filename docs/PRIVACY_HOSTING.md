# Hosting the SalahFocus privacy policy

The in-app privacy policy and legal notice are sourced from
`lib/app/legal/legal_documents.dart`. Do not maintain a separate hand-written
copy for the website.

Generate static, localized HTML from that same source:

```text
dart run tool/export_legal_documents.dart build/legal_site
```

The output includes English root files and one folder for every supported app
language. Publish the generated files on a public HTTPS host. Then configure the
canonical in-app link in the release build:

```text
flutter build appbundle --dart-define=PRIVACY_POLICY_URL=https://YOUR-REAL-DOMAIN/PATH/privacy-policy.html
flutter build ipa --dart-define=PRIVACY_POLICY_URL=https://YOUR-REAL-DOMAIN/PATH/privacy-policy.html
```

`PRIVACY_POLICY_URL` is intentionally empty by default. The app accepts and
shows only a valid `https://` value, so no placeholder or non-secure URL can
reach users accidentally.

Before publishing, replace `YOUR-REAL-DOMAIN/PATH` with the actual address,
regenerate the files, verify every language, and enter the public policy URL in
App Store Connect and Google Play Console.
