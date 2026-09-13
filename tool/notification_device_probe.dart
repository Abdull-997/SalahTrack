// Manual Android notification probe. Run with:
// flutter run -d emulator-5554 -t tool/notification_device_probe.dart
// Grant notifications/exact alarms/full-screen alarms on the test emulator.
// The first launch schedules Isha 25 seconds later. Fajr and Dhuhr are stored
// for warm/cold action replay through the plugin's Android activity intents.
// Probe rows use a separate date and IDs; subsequent launches preserve results.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/app.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/core/database/app_database.dart';
import 'package:salah_focus/core/notifications/local_notification_service.dart';
import 'package:salah_focus/core/time/timezone_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await TimezoneService.initialize();
  final database = AppDatabase();
  final notifications = LocalNotificationService();
  await notifications.initialize();
  final now = DateTime.now().toUtc();
  for (final type in [PrayerType.isha, PrayerType.fajr, PrayerType.dhuhr]) {
    final id = 'notification-probe-v2:${type.name}';
    if (await database.prayerEntryById(id) != null) continue;
    final entry = PrayerEntry(
      id: id,
      localDate: '2099-01-01',
      type: type,
      scheduledAtUtc: type == PrayerType.isha
          ? now.add(const Duration(seconds: 25))
          : now.subtract(const Duration(minutes: 5)),
      timezoneId: 'UTC',
      graceEndsAtUtc: now.add(const Duration(hours: 1)),
      trackingEndsAtUtc: now.add(const Duration(hours: 4)),
      status: PrayerStatus.upcoming,
    );
    await database.upsertPrayerEntry(entry);
    if (type == PrayerType.isha) {
      await notifications.schedulePrayer(entry, 'Isha', languageCode: 'en');
    }
  }
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        notificationServiceProvider.overrideWithValue(notifications),
        initialPreferencesProvider.overrideWithValue(
          const AppPreferences(
            prayerSettings: PrayerSettings(snoozeMinutes: 1, maxSnoozes: 2),
            localeCode: 'en',
            themeMode: 'light',
            onboardingComplete: true,
          ),
        ),
      ],
      child: const SalahFocusApp(),
    ),
  );
}
