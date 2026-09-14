import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/features/settings/presentation/settings_screen.dart';

Widget _app(Locale locale, {ThemeData? theme}) => ProviderScope(
  child: MaterialApp(
    theme: theme ?? AppTheme.light(),
    locale: locale,
    supportedLocales: AppStrings.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppStrings.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      AppStrings.cupertinoFallbackDelegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const SettingsScreen(),
  ),
);

void main() {
  for (final Locale locale in AppStrings.supportedLocales) {
    testWidgets(
      '${locale.languageCode} settings help is complete, scrollable, and fits a small screen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(
          tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
        );
        await tester.pumpWidget(
          _app(
            locale,
            theme: locale.languageCode == 'ur'
                ? AppTheme.dark()
                : AppTheme.light(),
          ),
        );
        await tester.pumpAndSettle();

        final Finder infoButton = find.byKey(
          const ValueKey<String>('settings-info-button'),
        );
        final Size touchSize = tester.getSize(infoButton);
        expect(touchSize.width, greaterThanOrEqualTo(48));
        expect(touchSize.height, greaterThanOrEqualTo(48));
        await tester.tap(infoButton);
        await tester.pumpAndSettle();

        final AppStrings s = AppStrings(locale);
        expect(find.text(s.t('settingsInfoTitle')), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        for (final String key in <String>[
          'locationHelp',
          'calculationMethodHelp',
          'asrCalculationHelp',
          'standardAsrHelp',
          'hanafiAsrHelp',
          'highLatitudeHelp',
          'highLatitudeMiddleOfNightHelp',
          'highLatitudeOneSeventhHelp',
          'highLatitudeAngleBasedHelp',
          'minuteAdjustmentsHelp',
          'gracePeriodHelp',
          'snoozeDurationHelp',
          'maxSnoozesHelp',
          'softReminderHelp',
          'confirmationTextHelp',
          'notificationPermissionHelp',
          'exactAlarmPermissionHelp',
        ]) {
          expect(find.text(s.t(key)), findsWidgets, reason: key);
        }
        final TextDirection expectedDirection =
            <String>{'ar', 'ps', 'ur'}.contains(locale.languageCode)
            ? TextDirection.rtl
            : TextDirection.ltr;
        expect(
          Directionality.of(tester.element(find.byType(AlertDialog))),
          expectedDirection,
        );
        final Finder close = find.text(s.t('close')).hitTestable();
        expect(close, findsOneWidget);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('settings help includes full-screen permission when it appears', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(const _AndroidSettingsHelpApp());
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-info-button')),
    );
    await tester.pumpAndSettle();
    final AppStrings s = AppStrings(const Locale('en'));
    expect(find.text(s.t('fullScreenAlarmPermissionHelp')), findsWidgets);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}

class _AndroidSettingsHelpApp extends StatelessWidget {
  const _AndroidSettingsHelpApp();

  @override
  Widget build(BuildContext context) => _app(const Locale('en'));
}
