import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/app.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_language.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/app/router/app_router.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_tracker/presentation/tracker_screen.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Notifications implements NotificationService {
  @override
  Stream<String> get payloads => const Stream.empty();
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> takeInitialPayload() async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final Locale locale in AppStrings.supportedLocales) {
    test(
      '${locale.languageCode} translates actions, permissions, and help text',
      () {
        final translations = AppStrings.translations[locale.languageCode]!;
        for (final key in [
          'markAsPrayed',
          'snoozeAction',
          'alhamdulillah',
          'fullScreenAlarmPermission',
          'fullScreenAlarmsEnabled',
          'fullScreenAlarmsDisabled',
          'fullScreenAlarmPermissionHelp',
          'openFullScreenAlarmSettings',
          'settingsInfo',
          'settingsInfoTitle',
          'trackerInfo',
          'trackerInfoTitle',
          'trackerInfoIntro',
          'monthInfo',
          'monthInfoTitle',
          'monthInfoOverview',
          'monthCountHelp',
          'monthAllConfirmedHelp',
          'monthPartiallyConfirmedHelp',
          'monthNoneConfirmedHelp',
          'monthFutureHelp',
          'monthTodayOutlineHelp',
          'statusUpcomingHelp',
          'statusActiveHelp',
          'statusPendingHelp',
          'statusSnoozedHelp',
          'statusPrayedHelp',
          'statusSkippedHelp',
          'statusMissedHelp',
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
          'fridayPrayer',
          'fridayPrayerTime',
          'fridayPrayerHelp',
          'fridayPrayerReminderOnly',
          'fridayPrayerInTwoHours',
          'fridayPrayerInOneHour',
          'gracePeriodHelp',
          'snoozeDurationHelp',
          'maxSnoozesHelp',
          'softReminderHelp',
          'confirmationTextHelp',
          'systemThemeHelp',
          'lightThemeHelp',
          'darkThemeHelp',
          'languageHelp',
        ]) {
          expect(translations[key]?.trim(), isNotEmpty, reason: key);
        }
        expect(
          AppStrings.translations['en']!.keys.toSet().difference(
            translations.keys.toSet(),
          ),
          isEmpty,
          reason: '${locale.languageCode} must not fall back to English',
        );
      },
    );
  }

  for (final String code in ['tr', 'fr', 'es']) {
    final AppStrings s = AppStrings(Locale(code));
    test('$code has every UI key and preserves interpolation parameters', () {
      final Map<String, String> source = AppStrings.translations['en']!;
      final Map<String, String> target = AppStrings.translations[code]!;
      expect(source.keys.toSet().difference(target.keys.toSet()), isEmpty);
      final RegExp parameter = RegExp(r'\{\w+\}');
      for (final String key in source.keys) {
        expect(target[key]!.trim(), isNotEmpty, reason: '$code/$key');
        expect(
          parameter.allMatches(target[key]!).map((m) => m.group(0)).toSet(),
          parameter.allMatches(source[key]!).map((m) => m.group(0)).toSet(),
          reason: '$code/$key',
        );
      }
      expect(
        s.t('confirmPrayer'),
        PrayerSettings.defaultConfirmationText(code),
      );
      expect(s.t('snoozeIn', params: {'minutes': '15'}), contains('15'));
      expect(s.t('appName'), target['appName']);
    });

    test(
      '$code persists the language and restores localized default text',
      () async {
        final SettingsRepository repository = SettingsRepository();
        await repository.saveLocale(code);
        final AppPreferences restored = await repository.load();
        expect(restored.localeCode, code);
        expect(restored.prayerSettings.confirmationText, s.t('confirmPrayer'));
        await repository.savePrayerSettings(
          restored.prayerSettings.copyWith(confirmationText: 'My own text'),
        );
        expect(
          (await repository.load()).prayerSettings.confirmationText,
          'My own text',
        );
      },
    );

    test('$code formats Gregorian and Hijri month names', () {
      final String month = switch (code) {
        'tr' => 'Eylül',
        'fr' => 'septembre',
        _ => 'septiembre',
      };
      expect(
        s.date(DateTime(2026, 9, 7), pattern: 'EEEE, d MMMM y'),
        contains(month),
      );
      final String hijriMonth = switch (code) {
        'tr' => 'Rebiülevvel',
        'fr' => 'Rabia al awal',
        _ => 'Rabi al-awwal',
      };
      expect(s.hijriDate('7 Rabīʿ al-awwal 1448'), '7 $hijriMonth 1448');
      expect(
        s.hijriDate('7 Jumādá al-ākhirah 1448'),
        isNot(contains('Jumādá')),
      );
      expect(s.number(12.5), '12,5');
    });

    testWidgets('$code picker updates settings, dialogs, home and month view', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final DateTime now = DateTime.now().toUtc();
      final String date = now.toIso8601String().substring(0, 10);
      final PrayerEntry prayer = PrayerEntry(
        id: '$date-fajr',
        localDate: date,
        type: PrayerType.fajr,
        scheduledAtUtc: now.add(const Duration(hours: 1)),
        timezoneId: 'UTC',
        graceEndsAtUtc: now.add(const Duration(hours: 2)),
        trackingEndsAtUtc: now.add(const Duration(hours: 3)),
        status: PrayerStatus.upcoming,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [
          initialPreferencesProvider.overrideWithValue(
            const AppPreferences(
              prayerSettings: PrayerSettings(),
              localeCode: 'en',
              themeMode: 'system',
              onboardingComplete: true,
            ),
          ),
          notificationServiceProvider.overrideWithValue(_Notifications()),
          todayPrayerDayProvider.overrideWith(
            (ref) async => PrayerDay(
              localDate: date,
              timezoneId: 'UTC',
              entries: [prayer],
              hijriDate: '7 Rabīʿ al-awwal 1448',
            ),
          ),
          trackerDataProvider.overrideWith(
            (ref) async => TrackerData(entries: [prayer], localNow: now),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(goRouterProvider);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SalahFocusApp(),
        ),
      );
      await tester.pumpAndSettle();
      router.go('/settings');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Choose language'), 350);
      await tester.tap(find.text('Choose language'));
      await tester.pumpAndSettle();
      for (final String language in ['Türkçe', 'Français', 'Español']) {
        expect(find.text(language), findsOneWidget);
      }
      await tester.tap(find.text(languageName(code)));
      await tester.pumpAndSettle();
      expect(container.read(settingsControllerProvider).localeCode, code);
      expect(find.text(s.t('settings')), findsWidgets);
      expect(find.text('Settings'), findsNothing);
      expect((await SettingsRepository().load()).localeCode, code);

      await tester.scrollUntilVisible(
        find.text(s.t('calculationMethod')).hitTestable(),
        -150,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.t('calculationMethod')));
      await tester.pumpAndSettle();
      final String calculation = switch (code) {
        'tr' => 'Dünya İslam Birliği',
        'fr' => 'Ligue islamique mondiale',
        _ => 'Liga del Mundo Islámico',
      };
      expect(find.text(calculation), findsWidgets);
      expect(find.text('Muslim World League'), findsNothing);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.t('highLatitude')));
      await tester.pumpAndSettle();
      expect(
        find.text(switch (code) {
          'tr' => 'Gecenin yedide biri',
          'fr' => 'Un septième de la nuit',
          _ => 'Un séptimo de la noche',
        }),
        findsOneWidget,
      );
      router.pop();
      await tester.pumpAndSettle();

      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.text(s.t('nextPrayer')), findsOneWidget);
      expect(find.text(s.t('upcoming')), findsOneWidget);
      expect(find.text('Next prayer'), findsNothing);
      router.go('/tracker');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(s.t('month')),
        300,
        scrollable: find
            .descendant(
              of: find.byType(TrackerScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text(s.t('month')), findsOneWidget);
      expect(find.text('Month'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
