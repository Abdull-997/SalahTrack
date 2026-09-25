import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/app.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_language.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/time/clock_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';
import 'package:salah_focus/features/prayer_times/presentation/home_screen.dart';
import 'package:salah_focus/features/prayer_tracker/presentation/tracker_screen.dart';
import 'package:salah_focus/features/qibla/presentation/qibla_screen.dart';
import 'package:salah_focus/features/ramadan/application/ramadan_providers.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_calendar.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_record.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';
import 'package:salah_focus/features/settings/presentation/settings_screen.dart';
import 'package:timezone/data/latest.dart' as timezone_data;

const String _locale = String.fromEnvironment('STORE_LOCALE', defaultValue: 'en');
final DateTime _now = DateTime.utc(2026, 3, 5, 12, 45);
const String _date = '2026-03-05';
const String _zone = 'Europe/Berlin';

class _FixedClock implements ClockService {
  const _FixedClock();
  @override
  DateTime nowUtc() => _now;
}

PrayerEntry _entry(String date, PrayerType type, int hour, int minute,
    PrayerStatus status) {
  final DateTime time = DateTime.utc(2026, 3, int.parse(date.substring(8)),
      hour - 1, minute);
  return PrayerEntry(
    id: '$date:${type.name}',
    localDate: date,
    type: type,
    scheduledAtUtc: time,
    timezoneId: _zone,
    graceEndsAtUtc: time.add(const Duration(hours: 1)),
    trackingEndsAtUtc: time.add(const Duration(hours: 4)),
    status: status,
    confirmedAtUtc: status == PrayerStatus.prayed
        ? time.add(const Duration(minutes: 12))
        : null,
  );
}

List<PrayerEntry> _entries(String date, {bool historical = false}) => <PrayerEntry>[
  _entry(date, PrayerType.fajr, 5, 12, PrayerStatus.prayed),
  _entry(date, PrayerType.dhuhr, 12, 24, PrayerStatus.prayed),
  _entry(date, PrayerType.asr, 15, 28,
      historical ? PrayerStatus.prayed : PrayerStatus.upcoming),
  _entry(date, PrayerType.maghrib, 18, 12,
      historical ? PrayerStatus.prayed : PrayerStatus.upcoming),
  _entry(date, PrayerType.isha, 19, 42,
      historical ? PrayerStatus.prayed : PrayerStatus.upcoming),
];

final PrayerDay _day = PrayerDay(
  localDate: _date,
  timezoneId: _zone,
  entries: _entries(_date),
  hijriDate: '16 Ramadan 1447',
  hijriDay: 16,
  hijriMonth: 9,
  hijriYear: 1447,
  sunriseUtc: DateTime.utc(2026, 3, 5, 5, 55),
);

final RamadanTodayData _ramadan = RamadanTodayData(
  prayerDay: _day,
  ramadanDate: const RamadanDate(day: 16, year: 1447),
  record: const RamadanRecord(
    localDate: _date,
    hijriYear: 1447,
    hijriDay: 16,
  ),
  goals: const [],
  completedGoalIds: const {},
);

final List<RamadanRecord> _ramadanHistory = List<RamadanRecord>.generate(
  16,
  (int index) => RamadanRecord(
    localDate: '2026-03-${(index + 1).toString().padLeft(2, '0')}',
    hijriYear: 1447,
    hijriDay: index + 1,
    fastingStatus: index < 15 ? FastingStatus.fasted : FastingStatus.notRecorded,
    tarawihCompleted: index < 15,
  ),
);

Future<void> _settle(WidgetTester tester) async {
  // The fake providers resolve immediately. Pump a fixed number of frames so
  // a background timer or animation cannot keep the test waiting forever.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  debugPrint('  Capturing $name.png');
  await binding.takeScreenshot(name).timeout(const Duration(seconds: 45));
}

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture real localized store screens', (WidgetTester tester) async {
    expect(appLanguages.map((language) => language.code), contains(_locale));
    await initializeDateFormatting();
    timezone_data.initializeTimeZones();

    final AppPreferences preferences = AppPreferences(
      prayerSettings: PrayerSettings(
        confirmationText: PrayerSettings.defaultConfirmationText(_locale),
      ),
      location: const UserLocation(
        latitude: 52.52,
        longitude: 13.405,
        city: 'Berlin',
        country: 'DE',
        timezoneId: _zone,
        isAutomatic: false,
      ),
      localeCode: _locale,
      themeMode: 'light',
      onboardingComplete: true,
      firstLaunchAtUtc: DateTime.utc(2026, 1, 1),
      reviewRequestAttempted: true,
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storeScreenshotModeProvider.overrideWithValue(true),
        initialPreferencesProvider.overrideWithValue(preferences),
        deviceTimezoneIdProvider.overrideWithValue(_zone),
        clockServiceProvider.overrideWithValue(const _FixedClock()),
        todayPrayerDayProvider.overrideWith((ref) async => _day),
        trackerDataProvider.overrideWith((ref) async => TrackerData(
          entries: [
            ..._entries('2026-03-03', historical: true),
            ..._entries('2026-03-04', historical: true),
            ..._day.entries,
          ],
          localNow: DateTime(2026, 3, 5, 13, 45),
          prayerDay: _day,
        )),
        ramadanTodayProvider.overrideWith((ref) async => _ramadan),
        ramadanTrackerDataProvider.overrideWith((ref) async =>
            RamadanTrackerData(
              today: _ramadan,
              records: _ramadanHistory,
              goals: const [],
              completedGoalIds: const {},
            )),
        qiblaScreenshotHeadingProvider.overrideWithValue(0),
      ],
      child: const SalahTrackApp(),
    ));
    await _settle(tester);
    // Android screenshots require an image-backed surface before capture.
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await _settle(tester);
    }

    debugPrint('  Opening Home');
    final BuildContext context = tester.element(find.byType(HomeScreen));
    final AppStrings strings = AppStrings.of(context);
    expect(strings.locale.languageCode, _locale);
    expect(Directionality.of(context), textDirectionForLanguage(_locale));
    if (_locale == 'de') expect(strings.t('settings'), 'Einstellungen');
    if (_locale == 'ar') expect(strings.t('settings'), 'الإعدادات');
    expect(find.text(strings.t('today')), findsWidgets);
    expect(find.byKey(const ValueKey<String>('ramadan-home-card')), findsOneWidget);
    await _capture(binding, '$_locale/01_home');

    final GoRouter router = GoRouter.of(context);
    debugPrint('  Opening Prayer Tracking');
    router.go('/tracker');
    await _settle(tester);
    expect(find.byType(TrackerScreen), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('today-stats-card')), findsOneWidget);
    await _capture(binding, '$_locale/02_tracking');

    debugPrint('  Opening Qibla');
    router.go('/qibla');
    await _settle(tester);
    expect(find.byType(QiblaScreen), findsOneWidget);
    expect(find.text(strings.t('qiblaDirection')), findsWidgets);
    await _capture(binding, '$_locale/03_qibla');

    debugPrint('  Opening Ramadan');
    router.go('/tracker');
    await _settle(tester);
    final Finder ramadan = find.byKey(
      const ValueKey<String>('ramadan-tracker-section'),
    );
    await tester.scrollUntilVisible(
      ramadan,
      400,
      maxScrolls: 15,
      scrollable: find.descendant(
        of: find.byType(TrackerScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.ensureVisible(ramadan);
    await _settle(tester);
    expect(ramadan, findsOneWidget);
    expect(find.text(strings.t('ramadanTracker')), findsWidgets);
    await _capture(binding, '$_locale/04_ramadan');

    debugPrint('  Opening Settings');
    router.go('/settings');
    await _settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text(strings.t('prayerTimes')), findsWidgets);
    await _capture(binding, '$_locale/05_settings');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
