import 'dart:io';

import 'package:salah_focus/app/legal/legal_document.dart';
import 'package:salah_focus/app/legal/legal_documents.dart';
import 'package:salah_focus/app/legal/privacy_legal_config.dart';

const Set<String> _rtlLanguages = <String>{'ar', 'fa', 'pa', 'ps', 'ur'};

const Map<String, String> _languageNames = <String, String>{
  'ar': 'العربية',
  'bn': 'বাংলা',
  'de': 'Deutsch',
  'en': 'English',
  'es': 'Español',
  'fa': 'فارسی',
  'fr': 'Français',
  'id': 'Bahasa Indonesia',
  'ms': 'Bahasa Melayu',
  'pa': 'پنجابی',
  'ps': 'پښتو',
  'tr': 'Türkçe',
  'ur': 'اردو',
};

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/export_legal_documents.dart <output-directory>',
    );
    exitCode = 64;
    return;
  }

  final Directory output = Directory(arguments.single)
    ..createSync(recursive: true);
  File('${output.path}${Platform.pathSeparator}styles.css')
      .writeAsStringSync(_styles);

  for (final String language in PrivacyLegalDocuments.supportedLanguages) {
    final Directory languageDirectory = Directory(
      '${output.path}${Platform.pathSeparator}$language',
    )..createSync(recursive: true);
    final LegalDocument privacy = PrivacyLegalDocuments.privacyPolicy(language);
    final LegalDocument notice = PrivacyLegalDocuments.legalNotice(language);
    _writeCombinedPage(
      File('${languageDirectory.path}${Platform.pathSeparator}index.html'),
      privacy,
      notice,
      language,
      '../',
    );
    _writeDocumentPage(
      File(
        '${languageDirectory.path}${Platform.pathSeparator}privacy-policy.html',
      ),
      privacy,
      notice,
      language,
      '../',
      isPrivacy: true,
    );
    _writeDocumentPage(
      File(
        '${languageDirectory.path}${Platform.pathSeparator}legal-notice.html',
      ),
      notice,
      privacy,
      language,
      '../',
      isPrivacy: false,
    );
    if (language != 'en') {
      // Keep the published privacy-xx.html routes working when this folder is
      // uploaded over the existing GitHub Pages site.
      _writeCombinedPage(
        File('${output.path}${Platform.pathSeparator}privacy-$language.html'),
        privacy,
        notice,
        language,
        '',
      );
    }
  }

  final LegalDocument englishPrivacy = PrivacyLegalDocuments.privacyPolicy(
    'en',
  );
  final LegalDocument englishNotice = PrivacyLegalDocuments.legalNotice('en');
  _writeCombinedPage(
    File('${output.path}${Platform.pathSeparator}index.html'),
    englishPrivacy,
    englishNotice,
    'en',
    '',
  );
  _writeDocumentPage(
    File('${output.path}${Platform.pathSeparator}privacy-policy.html'),
    englishPrivacy,
    englishNotice,
    'en',
    '',
    isPrivacy: true,
  );
  _writeDocumentPage(
    File('${output.path}${Platform.pathSeparator}legal-notice.html'),
    englishNotice,
    englishPrivacy,
    'en',
    '',
    isPrivacy: false,
  );
  stdout.writeln('Exported legal website to ${output.absolute.path}');
}

void _writeCombinedPage(
  File file,
  LegalDocument privacy,
  LegalDocument notice,
  String language,
  String rootPrefix,
) {
  final StringBuffer body =
      _pageStart('${privacy.title} · ${notice.title}', language, rootPrefix)
        ..writeln('<nav class="document-nav" aria-label="Documents">')
        ..writeln('<a href="#privacy">${_escape(privacy.title)}</a>')
        ..writeln('<a href="#legal">${_escape(notice.title)}</a>')
        ..writeln('</nav>')
        ..writeln('<article id="privacy">${_renderDocument(privacy)}</article>')
        ..writeln('<article id="legal">${_renderDocument(notice)}</article>')
        ..write(_pageEnd());
  file.writeAsStringSync(body.toString());
}

void _writeDocumentPage(
  File file,
  LegalDocument document,
  LegalDocument otherDocument,
  String language,
  String rootPrefix, {
  required bool isPrivacy,
}) {
  final String otherFile = isPrivacy
      ? 'legal-notice.html'
      : 'privacy-policy.html';
  final StringBuffer body = _pageStart(document.title, language, rootPrefix)
    ..writeln('<nav class="document-nav" aria-label="Documents">')
    ..writeln('<a href="index.html">SalahTrack</a>')
    ..writeln('<a href="$otherFile">${_escape(otherDocument.title)}</a>')
    ..writeln('</nav>')
    ..writeln('<article>${_renderDocument(document)}</article>')
    ..write(_pageEnd());
  file.writeAsStringSync(body.toString());
}

StringBuffer _pageStart(String title, String language, String rootPrefix) {
  final String direction = _rtlLanguages.contains(language) ? 'rtl' : 'ltr';
  final StringBuffer body = StringBuffer()
    ..writeln('<!doctype html>')
    ..writeln('<html lang="${_escape(language)}" dir="$direction">')
    ..writeln('<head>')
    ..writeln('<meta charset="utf-8">')
    ..writeln(
      '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">',
    )
    ..writeln('<meta name="color-scheme" content="light dark">')
    ..writeln('<title>${_escape(title)} · SalahTrack</title>')
    ..writeln('<link rel="stylesheet" href="${rootPrefix}styles.css">')
    ..writeln('</head><body>')
    ..writeln('<header class="site-header">')
    ..writeln('<a class="brand" href="${rootPrefix}index.html">SalahTrack</a>')
    ..writeln('<nav class="languages" aria-label="Language">');
  for (final String code in PrivacyLegalDocuments.supportedLanguages) {
    final String current = code == language ? ' aria-current="page"' : '';
    body.writeln(
      '<a lang="$code" dir="${_rtlLanguages.contains(code) ? 'rtl' : 'ltr'}" '
      'hreflang="$code" href="$rootPrefix$code/index.html"$current>'
      '${_escape(_languageNames[code]!)}</a>',
    );
  }
  return body
    ..writeln('</nav>')
    ..writeln('</header>')
    ..writeln('<main>');
}

String _renderDocument(LegalDocument document) {
  final StringBuffer body = StringBuffer()
    ..writeln('<h1>${_escape(document.title)}</h1>')
    ..writeln('<p class="updated">${_escape(document.lastUpdated)}</p>')
    ..writeln('<p>${_paragraph(document.introduction)}</p>');
  for (final LegalSection section in document.sections) {
    body.writeln('<section><h2>${_escape(section.title)}</h2>');
    for (final String paragraph in section.paragraphs) {
      body.writeln('<p>${_paragraph(paragraph)}</p>');
    }
    body.writeln('</section>');
  }
  return body.toString();
}

String _pageEnd() =>
    '</main><footer><span>SalahTrack</span><a dir="ltr" href="mailto:${PrivacyLegalConfig.contactEmail}">${PrivacyLegalConfig.contactEmail}</a></footer></body></html>';

String _paragraph(String value) {
  final String escaped = _escape(value).replaceAll('\n', '<br>');
  final String email = _escape(PrivacyLegalConfig.contactEmail);
  return escaped.replaceAll(
    email,
    '<a dir="ltr" href="mailto:$email">$email</a>',
  );
}

String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

const String _styles = '''
:root{color-scheme:light dark;--bg:#f5f7f5;--card:#fff;--text:#17211b;--muted:#59635d;--line:#d7ded9;--accent:#126846;--focus:#005fcc}
*{box-sizing:border-box}
html{font-family:system-ui,-apple-system,"Segoe UI",sans-serif;line-height:1.65;background:var(--bg);color:var(--text)}
body{margin:0;padding:max(16px,env(safe-area-inset-top)) max(16px,env(safe-area-inset-right)) max(24px,env(safe-area-inset-bottom)) max(16px,env(safe-area-inset-left))}
a{color:var(--accent);text-underline-offset:.18em}
a:focus-visible{outline:3px solid var(--focus);outline-offset:3px;border-radius:4px}
.site-header,main,footer{max-width:820px;margin-inline:auto}
.site-header{display:grid;gap:16px;padding-block:8px 20px}
.brand{font-size:1.45rem;font-weight:800;text-decoration:none;color:var(--text)}
.languages,.document-nav{display:flex;flex-wrap:wrap;gap:8px}
.languages a,.document-nav a{border:1px solid var(--line);border-radius:999px;padding:6px 11px;text-decoration:none;background:var(--card)}
.languages a[aria-current="page"]{border-color:var(--accent);font-weight:700}
.document-nav{margin-block:0 18px}
article{background:var(--card);border:1px solid var(--line);border-radius:18px;padding:clamp(18px,4vw,38px);box-shadow:0 6px 24px rgb(0 0 0/.05);overflow-wrap:anywhere}
article+article{margin-block-start:24px}
h1,h2{line-height:1.25;text-wrap:balance}
h1{font-size:clamp(1.75rem,5vw,2.5rem);margin-block-start:0}
h2{font-size:clamp(1.15rem,3vw,1.4rem);margin-block-start:1.8em}
.updated{color:var(--muted);font-size:.95rem}
footer{display:flex;flex-wrap:wrap;justify-content:space-between;gap:12px;padding-block:28px 4px;color:var(--muted)}
@media (max-width:420px){body{padding-inline:12px}.languages{gap:6px}.languages a{padding:5px 8px;font-size:.9rem}article{border-radius:14px}}
@media (prefers-color-scheme:dark){:root{--bg:#0f1512;--card:#17201b;--text:#edf5ef;--muted:#b7c4bb;--line:#35423a;--accent:#78d9ae;--focus:#9fc8ff}article{box-shadow:none}}
@media print{body{padding:0;background:#fff;color:#000}.site-header,.document-nav,footer{display:none}article{border:0;box-shadow:none;padding:0}article+article{break-before:page}}
''';
