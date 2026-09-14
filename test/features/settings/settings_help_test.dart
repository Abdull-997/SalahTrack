import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/features/settings/presentation/settings_screen.dart';

typedef _HelpCategory = ({
  String buttonKey,
  String titleKey,
  List<String> helpKeys,
});

const List<String> _allCategoryHelpKeys = <String>[
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
  'fridayPrayerHelp',
  'gracePeriodHelp',
  'snoozeDurationHelp',
  'maxSnoozesHelp',
  'softReminderHelp',
  'confirmationTextHelp',
  'notificationPermissionHelp',
  'exactAlarmPermissionHelp',
  'fullScreenAlarmPermissionHelp',
  'systemThemeHelp',
  'lightThemeHelp',
  'darkThemeHelp',
  'languageHelp',
];

const List<_HelpCategory> _helpCategories = <_HelpCategory>[
  (
    buttonKey: 'settings-info-prayer-times',
    titleKey: 'prayerTimes',
    helpKeys: <String>[
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
      'fridayPrayerHelp',
    ],
  ),
  (
    buttonKey: 'settings-info-permissions',
    titleKey: 'permissions',
    helpKeys: <String>[
      'notificationPermissionHelp',
      'exactAlarmPermissionHelp',
      'fullScreenAlarmPermissionHelp',
    ],
  ),
  (
    buttonKey: 'settings-info-reminders',
    titleKey: 'prayerReminders',
    helpKeys: <String>[
      'gracePeriodHelp',
      'snoozeDurationHelp',
      'maxSnoozesHelp',
      'softReminderHelp',
    ],
  ),
  (
    buttonKey: 'settings-info-confirmation',
    titleKey: 'confirmationText',
    helpKeys: <String>['confirmationTextHelp'],
  ),
  (
    buttonKey: 'settings-info-theme',
    titleKey: 'theme',
    helpKeys: <String>['systemThemeHelp', 'lightThemeHelp', 'darkThemeHelp'],
  ),
  (
    buttonKey: 'settings-info-language',
    titleKey: 'language',
    helpKeys: <String>['languageHelp'],
  ),
];

const List<String> _formerlyInlineHelpKeys = <String>[
  'locationHelp',
  'calculationMethodHelp',
  'asrCalculationHelp',
  'highLatitudeHelp',
  'minuteAdjustmentsHelp',
  'gracePeriodHelp',
  'snoozeDurationHelp',
  'maxSnoozesHelp',
  'softReminderHelp',
  'confirmationTextHelp',
];

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
  testWidgets('settings list shows values without permanent explanations', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(const Locale('en')));
    await tester.pumpAndSettle();

    final AppStrings s = AppStrings(const Locale('en'));
    for (final String key in _formerlyInlineHelpKeys) {
      expect(find.text(s.t(key)), findsNothing, reason: key);
    }
    expect(find.text(s.t('needLocation')), findsOneWidget);
    expect(find.text('Muslim World League'), findsOneWidget);
    expect(find.text(s.t('standard')), findsOneWidget);
    expect(find.text('Angle Based'), findsOneWidget);
    expect(find.text('Ich habe gebetet'), findsOneWidget);
    expect(
      find.widgetWithText(SwitchListTile, s.t('softReminder')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.info_outline_rounded),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

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

        final AppStrings s = AppStrings(locale);
        final TextDirection expectedDirection =
            <String>{'ar', 'ps', 'ur'}.contains(locale.languageCode)
            ? TextDirection.rtl
            : TextDirection.ltr;
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.info_outline_rounded),
          ),
          findsNothing,
        );

        for (final _HelpCategory category in _helpCategories) {
          final Finder infoButton = find.byKey(
            ValueKey<String>(category.buttonKey),
          );
          await tester.scrollUntilVisible(infoButton, 250);
          await tester.pumpAndSettle();
          final Size touchSize = tester.getSize(infoButton);
          expect(touchSize.width, greaterThanOrEqualTo(48));
          expect(touchSize.height, greaterThanOrEqualTo(48));
          await tester.tap(infoButton);
          await tester.pumpAndSettle();

          final Finder dialog = find.byType(AlertDialog);
          expect(dialog, findsOneWidget);
          expect(
            find.descendant(
              of: dialog,
              matching: find.text(s.t(category.titleKey)),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: dialog,
              matching: find.byType(SingleChildScrollView),
            ),
            findsOneWidget,
          );
          for (final String key in category.helpKeys) {
            expect(
              find.descendant(of: dialog, matching: find.text(s.t(key))),
              findsOneWidget,
              reason: '${category.buttonKey}/$key',
            );
          }
          for (final String key in _allCategoryHelpKeys) {
            if (category.helpKeys.contains(key)) continue;
            expect(
              find.descendant(of: dialog, matching: find.text(s.t(key))),
              findsNothing,
              reason: '${category.buttonKey} must not include $key',
            );
          }
          expect(Directionality.of(tester.element(dialog)), expectedDirection);
          final Finder close = find
              .descendant(of: dialog, matching: find.text(s.t('close')))
              .hitTestable();
          expect(close, findsOneWidget);
          await tester.tap(close);
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'permission category help includes full-screen permission when it appears',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(const _AndroidSettingsHelpApp());
      await tester.pumpAndSettle();
      final Finder permissionInfo = find.byKey(
        const ValueKey<String>('settings-info-permissions'),
      );
      await tester.scrollUntilVisible(permissionInfo, 250);
      await tester.pumpAndSettle();
      await tester.tap(permissionInfo.hitTestable());
      await tester.pumpAndSettle();
      final AppStrings s = AppStrings(const Locale('en'));
      final Finder dialog = find.byType(AlertDialog);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(s.t('fullScreenAlarmPermissionHelp')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(s.t('gracePeriodHelp')),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}

class _AndroidSettingsHelpApp extends StatelessWidget {
  const _AndroidSettingsHelpApp();

  @override
  Widget build(BuildContext context) => _app(const Locale('en'));
}
