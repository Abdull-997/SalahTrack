import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/app/localization/app_language.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/app/localization/report_problem_translations.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/features/settings/data/problem_report_service.dart';
import 'package:salah_focus/features/settings/domain/problem_report.dart';
import 'package:salah_focus/features/settings/presentation/report_problem_screen.dart';
import 'package:salah_focus/features/settings/presentation/settings_screen.dart';

class _Service implements ProblemReportService {
  _Service({this.openResult = true, this.failTechnicalInfo = false});

  bool openResult;
  bool failTechnicalInfo;
  Uri? openedUri;
  String? copiedText;

  @override
  Future<ProblemTechnicalInfo> loadTechnicalInfo(String languageCode) async {
    if (failTechnicalInfo) throw StateError('unavailable');
    return ProblemTechnicalInfo(
      appVersion: '1.2.3',
      buildNumber: '45',
      platform: 'Android',
      osVersion: 'Android 16 · SDK 36',
      deviceModel: 'Samsung Galaxy S25',
      languageCode: languageCode,
    );
  }

  @override
  Future<bool> openEmail(Uri uri) async {
    openedUri = uri;
    return openResult;
  }

  @override
  Future<void> copyText(String text) async => copiedText = text;
}

Widget _reportApp(
  Locale locale,
  ProblemReportService service, {
  Widget? home,
}) => MaterialApp(
  theme: AppTheme.light(languageCode: locale.languageCode),
  locale: locale,
  supportedLocales: AppStrings.supportedLocales,
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    AppStrings.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    AppStrings.cupertinoFallbackDelegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (BuildContext context, Widget? child) => Directionality(
    textDirection: textDirectionForLanguage(locale.languageCode),
    child: child ?? const SizedBox.shrink(),
  ),
  home: home ?? ReportProblemScreen(service: service),
);

Future<void> _selectCategory(
  WidgetTester tester,
  Locale locale,
  ProblemCategory category,
) async {
  final Finder field = find.byKey(const ValueKey('problem-category-field'));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(
    find.text(AppStrings(locale).t(category.localizationKey)).last,
  );
  await tester.pumpAndSettle();
}

Future<void> _reveal(
  WidgetTester tester,
  Finder target, {
  Finder? scrollable,
}) async {
  final Finder surface = scrollable ?? find.byType(Scrollable).first;
  for (int attempt = 0; attempt < 12 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(surface, const Offset(0, -400));
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _completeReport(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  ProblemCategory category = ProblemCategory.notifications,
}) async {
  await _selectCategory(tester, locale, category);
  await tester.enterText(
    find.byKey(const ValueKey('problem-description-field')),
    'Notifications do not appear.',
  );
  await tester.enterText(
    find.byKey(const ValueKey('problem-steps-field')),
    '1. Enable notifications\n2. Wait for prayer time',
  );
  await _reveal(
    tester,
    find.byKey(const ValueKey('review-problem-report-button')),
    scrollable: find.byType(Scrollable).first,
  );
  await tester.drag(
    find.byKey(const ValueKey<String>('problem-report-list')),
    const Offset(0, -100),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('report localization is complete for all supported locales', () {
    final Set<String> expected = reportProblemTranslations['en']!.keys.toSet();
    expect(
      reportProblemTranslations.keys.toSet(),
      AppStrings.supportedLocales
          .map((Locale locale) => locale.languageCode)
          .toSet(),
    );
    for (final Locale locale in AppStrings.supportedLocales) {
      final Map<String, String> catalog =
          reportProblemTranslations[locale.languageCode]!;
      expect(catalog.keys.toSet(), expected, reason: locale.languageCode);
      expect(
        catalog.values.every((String value) => value.trim().isNotEmpty),
        isTrue,
        reason: locale.languageCode,
      );
      expect(
        AppStrings(locale).t('reportProblem'),
        isNot('reportProblem'),
        reason: locale.languageCode,
      );
    }
  });

  test('generated report and mailto contain only reviewed report fields', () {
    final AppStrings strings = AppStrings(const Locale('en'));
    const ProblemReport report = ProblemReport(
      category: ProblemCategory.location,
      description: 'City search does not open.',
      steps: 'Open Settings and select Location.',
      technicalInfo: ProblemTechnicalInfo(
        appVersion: '1.2.3',
        buildNumber: '45',
        platform: 'iOS',
        osVersion: 'iOS 20.0',
        deviceModel: 'iPhone (iPhone18,1)',
        languageCode: 'en',
      ),
    );

    final String body = report.body(strings);
    expect(body, contains('Problem category:\nLocation'));
    expect(body, contains('Description:\nCity search does not open.'));
    expect(body, contains('Steps to reproduce:'));
    expect(body, contains('App version: 1.2.3'));
    expect(body, contains('Build: 45'));
    expect(body, contains('Platform: iOS'));
    expect(body, contains('OS: iOS 20.0'));
    expect(body, contains('Device: iPhone (iPhone18,1)'));
    expect(body, contains('Language: en'));
    expect(body.toLowerCase(), isNot(contains('latitude')));
    expect(body.toLowerCase(), isNot(contains('prayer history')));
    expect(body.toLowerCase(), isNot(contains('identifier')));

    final Uri uri = report.emailUri(strings);
    expect(uri.scheme, 'mailto');
    expect(uri.path, ProblemReport.recipient);
    expect(uri.queryParameters['subject'], ProblemReport.subject);
    expect(uri.queryParameters['body'], body);
  });

  testWidgets('Settings entry exists and opens ReportProblemScreen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final _Service service = _Service();
    await tester.pumpWidget(
      ProviderScope(
        child: _reportApp(
          const Locale('en'),
          service,
          home: SettingsScreen(problemReportService: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder tile = find.byKey(
      const ValueKey<String>('report-problem-settings-tile'),
    );
    await _reveal(tester, tile, scrollable: find.byType(Scrollable).first);
    expect(
      find.descendant(of: tile, matching: find.text('Report a problem')),
      findsOneWidget,
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(ReportProblemScreen), findsOneWidget);
    expect(
      find.text(
        'Briefly describe the problem you encountered while using SalahTrack.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('category and description are required', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_reportApp(const Locale('en'), _Service()));
    await tester.pumpAndSettle();
    final Finder review = find.byKey(
      const ValueKey<String>('review-problem-report-button'),
    );
    await _reveal(tester, review, scrollable: find.byType(Scrollable).first);
    await tester.tap(review);
    await tester.pumpAndSettle();

    expect(find.text('Please select a category.'), findsOneWidget);
    expect(find.text('Please describe the problem.'), findsOneWidget);
    expect(find.byKey(const ValueKey('problem-report-preview')), findsNothing);

    await _selectCategory(tester, const Locale('en'), ProblemCategory.qibla);
    expect(find.text('Qibla'), findsWidgets);
  });

  testWidgets('technical information is visible before email review', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_reportApp(const Locale('en'), _Service()));
    await tester.pumpAndSettle();

    final Finder technical = find.byKey(
      const ValueKey<String>('problem-technical-information'),
    );
    await tester.ensureVisible(technical);
    expect(
      find.descendant(of: technical, matching: find.text('1.2.3')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: technical, matching: find.text('45')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: technical, matching: find.text('Android')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: technical,
        matching: find.text('Android 16 · SDK 36'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: technical, matching: find.text('Samsung Galaxy S25')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: technical, matching: find.text('en')),
      findsOneWidget,
    );
  });

  testWidgets('technical information failure is safe and retryable', (
    WidgetTester tester,
  ) async {
    final _Service service = _Service(failTechnicalInfo: true);
    await tester.pumpWidget(_reportApp(const Locale('en'), service));
    await tester.pumpAndSettle();

    final Finder technical = find.byKey(
      const ValueKey<String>('problem-technical-information'),
    );
    await tester.ensureVisible(technical);
    expect(
      find.descendant(
        of: technical,
        matching: find.text('Some technical information could not be loaded.'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: technical, matching: find.text('Not available')),
      findsWidgets,
    );

    service.failTechnicalInfo = false;
    final Finder retry = find.descendant(
      of: technical,
      matching: find.text('Try again'),
    );
    await tester.ensureVisible(retry);
    await tester.drag(
      find.byKey(const ValueKey<String>('problem-report-list')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: technical, matching: find.text('Samsung Galaxy S25')),
      findsOneWidget,
    );
  });

  testWidgets('reviewed report opens a correctly populated mailto', (
    WidgetTester tester,
  ) async {
    final _Service service = _Service();
    await tester.pumpWidget(_reportApp(const Locale('en'), service));
    await tester.pumpAndSettle();
    await _completeReport(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('review-problem-report-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('problem-report-preview')),
      findsOneWidget,
    );
    expect(find.textContaining('Samsung Galaxy S25'), findsWidgets);
    expect(find.textContaining(ProblemReport.recipient), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-email-app-button')));
    await tester.pumpAndSettle();

    expect(service.openedUri, isNotNull);
    expect(service.openedUri?.scheme, 'mailto');
    expect(service.openedUri?.path, ProblemReport.recipient);
    expect(
      service.openedUri?.queryParameters['subject'],
      ProblemReport.subject,
    );
    expect(
      service.openedUri?.queryParameters['body'],
      contains('Notifications do not appear.'),
    );
  });

  testWidgets('unavailable mail app offers a copy fallback', (
    WidgetTester tester,
  ) async {
    final _Service service = _Service(openResult: false);
    await tester.pumpWidget(_reportApp(const Locale('en'), service));
    await tester.pumpAndSettle();
    await _completeReport(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('review-problem-report-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-email-app-button')));
    await tester.pumpAndSettle();

    expect(find.text('No email app available'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('copy-problem-report-button')),
    );
    await tester.pumpAndSettle();
    expect(service.copiedText, contains(ProblemReport.recipient));
    expect(service.copiedText, contains(ProblemReport.subject));
    expect(service.copiedText, contains('Notifications do not appear.'));
    expect(find.text('Report and email address copied.'), findsOneWidget);
  });

  for (final Locale locale in AppStrings.supportedLocales) {
    testWidgets(
      '${locale.languageCode} report screen is localized and directed',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_reportApp(locale, _Service()));
        await tester.pumpAndSettle();

        final AppStrings s = AppStrings(locale);
        expect(find.text(s.t('reportProblem')), findsOneWidget);
        expect(find.text(s.t('reportProblemIntro')), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byType(ReportProblemScreen))),
          textDirectionForLanguage(locale.languageCode),
        );
        await tester.enterText(
          find.byKey(const ValueKey('problem-description-field')),
          'Test',
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('report form remains usable on a wide RTL layout', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_reportApp(const Locale('fa'), _Service()));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(ReportProblemScreen))),
      TextDirection.rtl,
    );
    expect(
      find.byKey(const ValueKey<String>('problem-description-field')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
