# SalahTrack privacy documents

The canonical, localized privacy policy and legal notice are defined in:

```text
lib/app/legal/legal_documents.dart
```

The app renders that structured source directly. The same source generates the
public HTTPS version through `tool/export_legal_documents.dart`, preventing a
separate website copy from drifting away from the in-app policy.

For the technical data-flow, permission, SDK and store-declaration audit, see:

```text
docs/STORE_PRIVACY_AUDIT.md
```

For hosting and release configuration, see:

```text
docs/PRIVACY_HOSTING.md
```
