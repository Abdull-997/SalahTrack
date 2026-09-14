import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/core/review/review_request_policy.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_settings.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test(
    'Ramadan preferences survive master switch changes and restart',
    () async {
      final SettingsRepository repository = SettingsRepository();
      const RamadanSettings configured = RamadanSettings(
        enabled: false,
        suhurReminderEnabled: false,
        iftarReminderEnabled: true,
        tarawihTrackingEnabled: false,
        qiyamTrackingEnabled: true,
        suhurReminderMinutes: 45,
        iftarReminderMinutes: 15,
      );

      await repository.saveRamadanSettings(configured);
      final AppPreferences restored = await repository.load();

      expect(restored.ramadanSettings, configured);
      expect(restored.ramadanSettings.enabled, isFalse);
      expect(restored.ramadanSettings.qiyamTrackingEnabled, isTrue);
      expect(restored.ramadanSettings.suhurReminderMinutes, 45);
    },
  );

  test('first successful launch is stored once', () async {
    final SettingsRepository repository = SettingsRepository();
    final AppPreferences first = await repository.load();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final AppPreferences second = await repository.load();

    expect(first.firstLaunchAtUtc, isNotNull);
    expect(second.firstLaunchAtUtc, first.firstLaunchAtUtc);
  });

  test('review becomes eligible at 72 hours and only before one attempt', () {
    final DateTime firstLaunch = DateTime.utc(2026, 9, 1, 12);
    final AppPreferences preferences = AppPreferences(
      prayerSettings: const PrayerSettings(),
      localeCode: 'en',
      themeMode: 'system',
      onboardingComplete: true,
      firstLaunchAtUtc: firstLaunch,
    );

    expect(
      ReviewRequestPolicy.isEligible(
        preferences,
        firstLaunch.add(const Duration(hours: 71, minutes: 59)),
      ),
      isFalse,
    );
    expect(
      ReviewRequestPolicy.isEligible(
        preferences,
        firstLaunch.add(const Duration(hours: 72)),
      ),
      isTrue,
    );
    expect(
      ReviewRequestPolicy.isEligible(
        preferences.copyWith(reviewRequestAttempted: true),
        firstLaunch.add(const Duration(days: 10)),
      ),
      isFalse,
    );
  });

  test(
    'review attempt is persisted independently of Ramadan settings',
    () async {
      final SettingsRepository repository = SettingsRepository();
      await repository.saveRamadanSettings(
        const RamadanSettings(enabled: false),
      );
      await repository.markReviewRequestAttempted();

      final AppPreferences restored = await repository.load();
      expect(restored.ramadanSettings.enabled, isFalse);
      expect(restored.reviewRequestAttempted, isTrue);
    },
  );
}
