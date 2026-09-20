import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/features/prayer_times/data/prayer_cache_key.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'manual change stores new coordinates and changes prayer cache key',
    () async {
      SharedPreferences.setMockInitialValues({});
      const first = UserLocation(
        latitude: 52.52,
        longitude: 13.405,
        city: 'Berlin',
        country: 'Deutschland',
        timezoneId: 'Europe/Berlin',
        isAutomatic: false,
      );
      const second = UserLocation(
        latitude: 51.2277,
        longitude: 6.7735,
        city: 'Düsseldorf',
        country: 'Deutschland',
        timezoneId: 'Europe/Berlin',
        isAutomatic: false,
      );
      final container = ProviderContainer(
        overrides: [
          initialPreferencesProvider.overrideWithValue(
            const AppPreferences(
              prayerSettings: PrayerSettings(),
              localeCode: 'de',
              themeMode: 'system',
              onboardingComplete: true,
              location: first,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(settingsControllerProvider.notifier)
          .setLocation(second);
      expect(
        container.read(settingsControllerProvider).location?.latitude,
        51.2277,
      );
      expect(
        container.read(settingsControllerProvider).location?.label,
        'Düsseldorf, Deutschland',
      );
      expect(
        PrayerCacheKey.build(first, const PrayerSettings()),
        isNot(PrayerCacheKey.build(second, const PrayerSettings())),
      );
      final saved = await SettingsRepository().load();
      expect(saved.location?.longitude, 6.7735);
    },
  );

  test(
    'automatic coordinates still use the same saved location structure',
    () async {
      SharedPreferences.setMockInitialValues({});
      const automatic = UserLocation(
        latitude: 24.86,
        longitude: 67.01,
        city: 'Karachi',
        country: 'Pakistan',
        timezoneId: 'Asia/Karachi',
        isAutomatic: true,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(settingsControllerProvider.notifier)
          .setLocation(automatic);
      expect(
        container.read(settingsControllerProvider).location?.isAutomatic,
        isTrue,
      );
      expect((await SettingsRepository().load()).location?.latitude, 24.86);
    },
  );
}
