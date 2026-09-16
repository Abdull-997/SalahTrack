import 'package:salah_focus/app/legal/privacy_legal_config.dart';

class LegalSection {
  const LegalSection({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;

  LegalSection resolved() => LegalSection(
    title: _resolveLegalTokens(title),
    paragraphs: paragraphs.map(_resolveLegalTokens).toList(growable: false),
  );
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.lastUpdated,
    required this.introduction,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final String introduction;
  final List<LegalSection> sections;

  LegalDocument resolved() => LegalDocument(
    title: _resolveLegalTokens(title),
    lastUpdated: _resolveLegalTokens(lastUpdated),
    introduction: _resolveLegalTokens(introduction),
    sections: sections
        .map((LegalSection section) => section.resolved())
        .toList(growable: false),
  );
}

String _resolveLegalTokens(String value) => value
    .replaceAll('{controller}', PrivacyLegalConfig.controllerName)
    .replaceAll('{location}', PrivacyLegalConfig.controllerLocation)
    .replaceAll('{email}', PrivacyLegalConfig.contactEmail)
    .replaceAll('{linkedin}', PrivacyLegalConfig.linkedInName);
