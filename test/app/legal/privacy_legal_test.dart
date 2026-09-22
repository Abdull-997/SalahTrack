import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/app/legal/legal_document.dart';
import 'package:salah_focus/app/legal/legal_documents.dart';
import 'package:salah_focus/app/legal/privacy_legal_config.dart';
import 'package:salah_focus/app/localization/app_language.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/features/settings/presentation/privacy_legal_screen.dart';

void main() {
  test('official in-app privacy and legal contact is current', () {
    expect(PrivacyLegalConfig.contactEmail, 'salahfoucus@gmail.com');
    expect(PrivacyLegalConfig.contactEmail, isNot('ar830222@gmail.com'));
  });

  test('privacy and legal UI catalogs are complete for every app language', () {
    final Map<String, Map<String, String>> catalogs =
        AppStrings.privacyLegalTranslations;
    final Set<String> expectedKeys = catalogs['en']!.keys.toSet();

    expect(
      catalogs.keys.toSet(),
      appLanguages.map((item) => item.code).toSet(),
    );
    for (final AppLanguage language in appLanguages) {
      expect(
        catalogs[language.code]!.keys.toSet(),
        expectedKeys,
        reason: '${language.code} must not fall back for Privacy & Legal UI',
      );
      expect(
        catalogs[language.code]!.values.every(
          (String value) => value.isNotEmpty,
        ),
        isTrue,
      );
    }
  });

  test('every app language has complete resolved legal documents', () {
    expect(
      PrivacyLegalDocuments.supportedLanguages.toSet(),
      appLanguages.map((item) => item.code).toSet(),
    );

    for (final AppLanguage language in appLanguages) {
      final privacy = PrivacyLegalDocuments.privacyPolicy(language.code);
      final notice = PrivacyLegalDocuments.legalNotice(language.code);
      expect(privacy.sections, hasLength(9), reason: language.code);
      expect(
        privacy.sections[3].paragraphs,
        hasLength(3),
        reason: language.code,
      );
      expect(notice.sections, hasLength(4), reason: language.code);
      expect(privacy.title, isNotEmpty);
      expect(notice.title, isNotEmpty);
      final String allText = <String>[
        privacy.title,
        privacy.introduction,
        notice.title,
        notice.introduction,
        for (final LegalSection section in <LegalSection>[
          ...privacy.sections,
          ...notice.sections,
        ]) ...<String>[section.title, ...section.paragraphs],
      ].join('\n');
      expect(allText, isNot(contains('{controller}')), reason: language.code);
      expect(allText, isNot(contains('{location}')), reason: language.code);
      expect(allText, contains(PrivacyLegalConfig.controllerName));
      expect(allText, contains(PrivacyLegalConfig.controllerLocation));
      expect(allText, contains(PrivacyLegalConfig.contactEmail));
      expect(allText, contains('salahfoucus@gmail.com'));
      expect(allText, isNot(contains('ar830222@gmail.com')));
      expect(allText, contains('photon.komoot.io'), reason: language.code);
      expect(allText, contains('OpenStreetMap'), reason: language.code);
      expect(allText, contains('api.aladhan.com'), reason: language.code);
      expect(
        allText,
        isNot(
          contains(
            'Salah'
            'Focus',
          ),
        ),
        reason: language.code,
      );
    }
  });

  test('hosted policy uses the published HTTPS URL by default', () {
    expect(
      PrivacyLegalConfig.privacyPolicyUrl,
      'https://abalh101.github.io/salahtrack-privacy/index.html',
    );
    expect(
      PrivacyLegalConfig.privacyPolicyUri,
      Uri.parse('https://abalh101.github.io/salahtrack-privacy/index.html'),
    );
  });

  for (final AppLanguage language in appLanguages) {
    testWidgets('${language.code} Privacy & Legal screen renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_TestApp(language: language));
      await tester.pumpAndSettle();

      final AppStrings strings = AppStrings(appLocaleFor(language.code));
      expect(find.text(strings.t('privacyLegal')), findsOneWidget);
      expect(find.text(strings.t('privacyPolicy')), findsOneWidget);
      expect(find.text(strings.t('legalNotice')), findsOneWidget);
      expect(find.text(strings.t('openSourceLicenses')), findsOneWidget);
      expect(find.text(strings.t('appVersion')), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(PrivacyLegalScreen))),
        language.textDirection,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('privacy policy opens and shows controller contact details', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 12000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final AppLanguage english = appLanguages.firstWhere(
      (AppLanguage language) => language.code == 'en',
    );
    await tester.pumpWidget(_TestApp(language: english));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('privacy-policy-tile')));
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsWidgets);
    expect(
      find.textContaining(PrivacyLegalConfig.controllerName),
      findsWidgets,
    );
    expect(find.textContaining(PrivacyLegalConfig.contactEmail), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('online-privacy-policy-link')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: appLocaleFor(language.code),
    supportedLocales: AppStrings.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppStrings.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      AppStrings.cupertinoFallbackDelegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (BuildContext context, Widget? child) => Directionality(
      textDirection: language.textDirection,
      child: child ?? const SizedBox.shrink(),
    ),
    home: const PrivacyLegalScreen(),
  );
}
