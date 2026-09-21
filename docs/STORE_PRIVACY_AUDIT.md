# SalahTrack store privacy audit

The current source-based data inventory and manual store-form guidance is kept
in [`../STORE_PRIVACY_CHECKLIST.md`](../STORE_PRIVACY_CHECKLIST.md).

The canonical localized policy text is
`lib/app/legal/legal_documents.dart`. Generate the upload-ready website with:

```text
dart run tool/export_legal_documents.dart privacy_site_update
```
