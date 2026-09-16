import 'dart:io';

import 'package:salah_focus/app/legal/legal_document.dart';
import 'package:salah_focus/app/legal/legal_documents.dart';

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
  for (final String language in PrivacyLegalDocuments.supportedLanguages) {
    final Directory languageDirectory = Directory(
      '${output.path}${Platform.pathSeparator}$language',
    )..createSync(recursive: true);
    _writeDocument(
      File(
        '${languageDirectory.path}${Platform.pathSeparator}privacy-policy.html',
      ),
      PrivacyLegalDocuments.privacyPolicy(language),
      language,
    );
    _writeDocument(
      File(
        '${languageDirectory.path}${Platform.pathSeparator}legal-notice.html',
      ),
      PrivacyLegalDocuments.legalNotice(language),
      language,
    );
  }

  _writeDocument(
    File('${output.path}${Platform.pathSeparator}privacy-policy.html'),
    PrivacyLegalDocuments.privacyPolicy('en'),
    'en',
  );
  _writeDocument(
    File('${output.path}${Platform.pathSeparator}legal-notice.html'),
    PrivacyLegalDocuments.legalNotice('en'),
    'en',
  );
  stdout.writeln('Exported legal documents to ${output.absolute.path}');
}

void _writeDocument(File file, LegalDocument document, String language) {
  const Set<String> rtlLanguages = <String>{'ar', 'fa', 'pa', 'ps', 'ur'};
  final String direction = rtlLanguages.contains(language) ? 'rtl' : 'ltr';
  final StringBuffer body = StringBuffer()
    ..writeln('<!doctype html>')
    ..writeln('<html lang="${_escape(language)}" dir="$direction">')
    ..writeln('<head>')
    ..writeln('<meta charset="utf-8">')
    ..writeln(
      '<meta name="viewport" content="width=device-width,initial-scale=1">',
    )
    ..writeln('<title>${_escape(document.title)} · SalahFocus</title>')
    ..writeln(
      '<style>body{font-family:system-ui,sans-serif;line-height:1.6;max-width:760px;margin:auto;padding:24px;color:#17211b}h1,h2{line-height:1.25}small{color:#59635d}</style>',
    )
    ..writeln('</head><body>')
    ..writeln('<main>')
    ..writeln('<h1>${_escape(document.title)}</h1>')
    ..writeln('<small>${_escape(document.lastUpdated)}</small>')
    ..writeln('<p>${_paragraph(document.introduction)}</p>');
  for (final LegalSection section in document.sections) {
    body.writeln('<section><h2>${_escape(section.title)}</h2>');
    for (final String paragraph in section.paragraphs) {
      body.writeln('<p>${_paragraph(paragraph)}</p>');
    }
    body.writeln('</section>');
  }
  body.writeln('</main></body></html>');
  file.writeAsStringSync(body.toString());
}

String _paragraph(String value) => _escape(value).replaceAll('\n', '<br>');

String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
