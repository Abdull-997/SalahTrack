import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/app/localization/reminder_exception_translations.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/settings/presentation/reminder_exceptions_section.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('new labels exist in every supported language', () {
    const keys = <String>{
      'reminderExceptions',
      'disableRemindersForPrayer',
      'everyDay',
      'selectedWeekdays',
      'weekdays',
      'noReminderExceptions',
      'addException',
      'editException',
      'deleteException',
      'remindersDisabled',
    };
    for (final Locale locale in AppStrings.supportedLocales) {
      expect(
        reminderExceptionTranslations[locale.languageCode]?.keys.toSet(),
        keys,
        reason: locale.languageCode,
      );
    }
  });

  testWidgets('add, edit, and delete a weekday exception', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    PrayerSettings settings = const PrayerSettings();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          AppStrings.cupertinoFallbackDelegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: StatefulBuilder(
          builder: (context, update) => Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: ReminderExceptionsSection(
                  settings: settings,
                  onChanged: (PrayerSettings next) async =>
                      update(() => settings = next),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No reminder exceptions'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('add-reminder-exception')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('exception-prayer')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maghrib').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('exception-repeat')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selected weekdays').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey<String>('exception-weekday-4')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(
      settings.remindersDisabledFor(PrayerType.maghrib, '2026-10-01'),
      isTrue,
    );
    expect(
      settings.remindersDisabledFor(PrayerType.maghrib, '2026-10-02'),
      isFalse,
    );

    await tester.tap(find.byKey(const ValueKey<String>('exception-maghrib')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('exception-repeat')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Every day').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(
      settings.remindersDisabledFor(PrayerType.maghrib, '2026-10-02'),
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('delete-exception-maghrib')),
    );
    await tester.pumpAndSettle();
    expect(settings.reminderExceptions, isEmpty);
    expect(find.text('No reminder exceptions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic exception dialog keeps right-to-left layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          AppStrings.cupertinoFallbackDelegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: ReminderExceptionsSection(
            settings: const PrayerSettings(),
            onChanged: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('add-reminder-exception')),
    );
    await tester.pumpAndSettle();
    final Finder dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    expect(Directionality.of(tester.element(dialog)), TextDirection.rtl);
    expect(
      find.text(AppStrings(const Locale('ar')).t('disableRemindersForPrayer')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('exception-repeat')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(AppStrings(const Locale('ar')).t('selectedWeekdays')).last,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
