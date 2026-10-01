import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/app/localization/statistics_translations.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/core/time/clock_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';
import 'package:salah_focus/features/settings/presentation/settings_screen.dart';
import 'package:salah_focus/features/statistics/presentation/statistics_screen.dart';

class _Clock implements ClockService {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 10, 1, 12);
}

PrayerEntry _entry(
  String date,
  PrayerType type,
  PrayerStatus status, {
  int snoozes = 0,
  String? reason,
}) {
  final DateTime scheduled = DateTime.parse('${date}T06:00:00Z');
  return PrayerEntry(
    id: '$date-${type.name}',
    localDate: date,
    type: type,
    scheduledAtUtc: scheduled,
    timezoneId: 'UTC',
    graceEndsAtUtc: scheduled.add(const Duration(minutes: 15)),
    trackingEndsAtUtc: scheduled.add(const Duration(hours: 5)),
    status: status,
    snoozeCount: snoozes,
    dismissReason: reason,
  );
}

Widget _app({
  required List<PrayerEntry> entries,
  Locale locale = const Locale('en'),
  bool fromSettings = false,
}) => ProviderScope(
    overrides: [
    initialPreferencesProvider.overrideWithValue(
      AppPreferences(
        prayerSettings: const PrayerSettings(),
        localeCode: locale.languageCode,
        themeMode: 'light',
        onboardingComplete: true,
      ),
    ),
    clockServiceProvider.overrideWithValue(_Clock()),
    statisticsHistoryProvider.overrideWith((ref) async => entries),
    todayPrayerDayProvider.overrideWith((ref) async => null),
  ],
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: locale,
    supportedLocales: AppStrings.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppStrings.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      AppStrings.cupertinoFallbackDelegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: fromSettings ? const SettingsScreen() : const StatisticsScreen(),
  ),
);

void main() {
  setUpAll(initializeDateFormatting);

  test('statistics labels exist in every supported language', () {
    const keys = <String>{
      'statistics',
      'last7Days',
      'last30Days',
      'thisMonth',
      'allTime',
      'completion',
      'overallCompletion',
      'completeDays',
      'currentStreak',
      'bestStreak',
      'delayedPrayers',
      'mostDelayedPrayer',
      'reasons',
      'noReasonProvided',
      'noPrayerHistoryYet',
      'noDelayedPrayers',
      'noReasonsRecorded',
      'snoozeActions',
      'stoppedReminders',
      'reasonScopeHelp',
      'prayersByType',
    };
    for (final Locale locale in AppStrings.supportedLocales) {
      expect(
        statisticsTranslations[locale.languageCode]?.keys.toSet(),
        keys,
        reason: locale.languageCode,
      );
    }
  });

  testWidgets(
    'Settings opens an empty localized statistics screen on a small RTL phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(
          entries: <PrayerEntry>[],
          locale: const Locale('ar'),
          fromSettings: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('open-statistics')));
      await tester.pumpAndSettle();
      final AppStrings s = AppStrings(const Locale('ar'));
      expect(find.byType(StatisticsScreen), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(StatisticsScreen))),
        TextDirection.rtl,
      );
      expect(find.text(s.t('noPrayerHistoryYet')), findsOneWidget);
      expect(find.text(s.t('noDelayedPrayers')), findsOneWidget);
      expect(find.text(s.t('noReasonsRecorded')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('range selection updates displayed completion and reasons', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        entries: <PrayerEntry>[
          _entry('2026-09-01', PrayerType.fajr, PrayerStatus.prayed),
          _entry('2026-10-01', PrayerType.fajr, PrayerStatus.missed),
          _entry(
            '2026-10-01',
            PrayerType.maghrib,
            PrayerStatus.skipped,
            reason: 'preset:reasonOutside',
          ),
          _entry('2026-10-01', PrayerType.asr, PrayerStatus.prayed, snoozes: 2),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Overall completion'), findsOneWidget);
    // Default 30-day range excludes September 1.
    expect(find.text('33%'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('statistics-range')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All time').last);
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);
    final Finder reasons = find.text('Reasons');
    await tester.scrollUntilVisible(reasons, 250);
    expect(find.text('I am outside'), findsOneWidget);
    expect(find.text('No reason provided'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
