import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_times/domain/friday_prayer_settings.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  test('default confirmation text is available for every app language', () {
    expect(PrayerSettings.defaultConfirmationText('de'), 'Ich habe gebetet');
    expect(PrayerSettings.defaultConfirmationText('en'), 'I have prayed');
    expect(PrayerSettings.defaultConfirmationText('ar'), 'لقد صليت');
    expect(PrayerSettings.defaultConfirmationText('ur'), 'میں نے نماز پڑھی ہے');
    expect(PrayerSettings.defaultConfirmationText('ps'), 'ما لمونځ کړی دی');
  });

  test('settings round-trip preserves prayer calculation configuration', () {
    final PrayerSettings value = PrayerSettings(
      calculationMethodId: 13,
      madhhab: AsrMadhhab.hanafi,
      highLatitudeRule: HighLatitudeRule.angleBased,
      gracePeriodMinutes: 45,
      snoozeMinutes: 15,
      maxSnoozes: 3,
      softReminderAfterSkip: false,
      confirmationText: 'Alhamdulillah, erledigt',
      adjustments: const <PrayerType, int>{
        PrayerType.fajr: 2,
        PrayerType.isha: -2,
      },
      fridayPrayer: const FridayPrayerSettings(
        enabled: true,
        manualMinutesFromMidnight: 13 * 60 + 45,
      ),
    );

    final PrayerSettings decoded = PrayerSettings.fromJson(value.toJson());
    expect(decoded.calculationMethodId, 13);
    expect(decoded.madhhab, AsrMadhhab.hanafi);
    expect(decoded.highLatitudeRule, HighLatitudeRule.angleBased);
    expect(decoded.gracePeriodMinutes, 45);
    expect(decoded.snoozeMinutes, 15);
    expect(decoded.maxSnoozes, 3);
    expect(decoded.adjustmentFor(PrayerType.fajr), 2);
    expect(decoded.adjustmentFor(PrayerType.isha), -2);
    expect(decoded.fridayPrayer.enabled, isTrue);
    expect(decoded.fridayPrayer.manualMinutesFromMidnight, 13 * 60 + 45);
  });

  test('invalid stored values are sanitized instead of crashing', () {
    final PrayerSettings decoded = PrayerSettings.fromJson(<String, Object?>{
      'calculationMethodId': 999,
      'madhhab': 'future_value',
      'highLatitudeRule': 'future_value',
      'gracePeriodMinutes': -500,
      'snoozeMinutes': 900,
      'maxSnoozes': 99,
      'confirmationText': '   ',
      'adjustments': <String, int>{'fajr': 999},
      'fridayPrayer': <String, Object?>{
        'enabled': true,
        'minutesFromMidnight': 99999,
      },
    });

    expect(decoded.calculationMethodId, 3);
    expect(decoded.madhhab, AsrMadhhab.standard);
    expect(decoded.highLatitudeRule, HighLatitudeRule.angleBased);
    expect(decoded.gracePeriodMinutes, 0);
    expect(decoded.snoozeMinutes, 30);
    expect(decoded.maxSnoozes, 5);
    expect(decoded.adjustmentFor(PrayerType.fajr), 60);
    expect(decoded.confirmationText, 'Ich habe gebetet');
    expect(decoded.fridayPrayer.enabled, isTrue);
    expect(decoded.fridayPrayer.manualMinutesFromMidnight, 1439);
  });

  test('older settings keep Friday Prayer disabled by default', () {
    final PrayerSettings decoded = PrayerSettings.fromJson(<String, Object?>{
      'calculationMethodId': 3,
    });

    expect(decoded.fridayPrayer, const FridayPrayerSettings());
    expect(decoded.fridayPrayer.enabled, isFalse);
    expect(decoded.fridayPrayer.manualMinutesFromMidnight, isNull);
    expect(decoded.fridayPrayer.usesDhuhrTime, isTrue);
  });

  test('fresh and missing reminder values use 15 minute grace and 20 minute snooze', () {
    expect(PrayerSettings().gracePeriodMinutes, 15);
    expect(PrayerSettings().snoozeMinutes, 20);
    final PrayerSettings decoded = PrayerSettings.fromJson(<String, Object?>{});
    expect(decoded.gracePeriodMinutes, 15);
    expect(decoded.snoozeMinutes, 20);
  });

  test(
    'explicit saved reminder values, including old defaults, are preserved',
    () {
      final PrayerSettings decoded = PrayerSettings.fromJson(<String, Object?>{
        'gracePeriodMinutes': 60,
        'snoozeMinutes': 5,
      });
      expect(decoded.gracePeriodMinutes, 60);
      expect(decoded.snoozeMinutes, 5);
    },
  );

  test('legacy fixed 13:30 placeholder migrates to automatic Dhuhr mode', () {
    final FridayPrayerSettings automatic = FridayPrayerSettings.fromJson(
      <String, Object?>{'enabled': true, 'minutesFromMidnight': 13 * 60 + 30},
    );
    final FridayPrayerSettings custom = FridayPrayerSettings.fromJson(
      <String, Object?>{'enabled': true, 'minutesFromMidnight': 12 * 60 + 45},
    );
    expect(automatic.usesDhuhrTime, isTrue);
    expect(custom.manualMinutesFromMidnight, 12 * 60 + 45);
  });

  test(
    'automatic Jumuah stays dynamic while a manual time overrides Dhuhr',
    () {
      const FridayPrayerSettings automatic = FridayPrayerSettings(
        enabled: true,
      );
      const FridayPrayerSettings manual = FridayPrayerSettings(
        enabled: true,
        manualMinutesFromMidnight: 12 * 60 + 45,
      );
      expect(
        automatic.effectiveMinutesFromMidnight(13 * 60 + 28),
        13 * 60 + 28,
      );
      expect(
        automatic.effectiveMinutesFromMidnight(13 * 60 + 12),
        13 * 60 + 12,
      );
      expect(manual.effectiveMinutesFromMidnight(13 * 60 + 28), 12 * 60 + 45);
    },
  );

  test(
    'custom reminder and Jumuah values persist without being overwritten',
    () async {
      final SettingsRepository repository = SettingsRepository();
      const PrayerSettings custom = PrayerSettings(
        gracePeriodMinutes: 35,
        snoozeMinutes: 25,
        fridayPrayer: FridayPrayerSettings(
          enabled: true,
          manualMinutesFromMidnight: 12 * 60 + 45,
        ),
      );
      await repository.savePrayerSettings(custom);
      final PrayerSettings reloaded = (await repository.load()).prayerSettings;
      expect(reloaded.gracePeriodMinutes, 35);
      expect(reloaded.snoozeMinutes, 25);
      expect(reloaded.fridayPrayer.manualMinutesFromMidnight, 12 * 60 + 45);
    },
  );
}
