import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_focus/core/api/api_client.dart';
import 'package:salah_focus/core/database/app_database.dart';
import 'package:salah_focus/core/location/location_service.dart';
import 'package:salah_focus/core/location/location_service_impl.dart';
import 'package:salah_focus/core/notifications/local_notification_service.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/core/notifications/friday_prayer_reminder_planner.dart';
import 'package:salah_focus/core/time/clock_service.dart';
import 'package:salah_focus/features/prayer_times/application/prayer_coordinator.dart';
import 'package:salah_focus/features/prayer_times/data/aladhan_prayer_times_provider.dart';
import 'package:salah_focus/features/prayer_times/data/prayer_times_provider.dart';
import 'package:salah_focus/features/prayer_times/data/prayer_times_repository_impl.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_times_repository.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';

final Provider<String> deviceTimezoneIdProvider = Provider<String>(
  (Ref ref) => 'UTC',
);

final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>(
  (Ref ref) => AppDatabase(),
);

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>(
  (Ref ref) => ApiClient(),
);

final Provider<PrayerTimesProvider> prayerTimesProvider =
    Provider<PrayerTimesProvider>(
      (Ref ref) => AlAdhanPrayerTimesProvider(ref.watch(apiClientProvider)),
    );

final Provider<PrayerTimesRepository> prayerTimesRepositoryProvider =
    Provider<PrayerTimesRepository>(
      (Ref ref) => PrayerTimesRepositoryImpl(
        ref.watch(appDatabaseProvider),
        ref.watch(prayerTimesProvider),
      ),
    );

final Provider<LocationService> locationServiceProvider =
    Provider<LocationService>((Ref ref) => LocationServiceImpl());

final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>(
      (Ref ref) => LocalNotificationService(
        languageCode: () => ref.read(settingsControllerProvider).localeCode,
      ),
    );

final notificationPayloadProvider =
    StreamNotifierProvider<NotificationPayloads, String>(
      NotificationPayloads.new,
    );

class NotificationPayloads extends StreamNotifier<String> {
  @override
  Stream<String> build() => ref.watch(notificationServiceProvider).payloads;

  // These values are tap events, not state snapshots. Riverpod's default
  // equality filtering would discard a later retry of the same notification.
  // The app applies its own short duplicate-delivery window.
  @override
  bool updateShouldNotify(
    AsyncValue<String> previous,
    AsyncValue<String> next,
  ) => true;
}

final Provider<ClockService> clockServiceProvider = Provider<ClockService>(
  (Ref ref) => const SystemClockService(),
);

final Provider<FridayPrayerReminderPlanner>
fridayPrayerReminderPlannerProvider = Provider<FridayPrayerReminderPlanner>(
  (Ref ref) =>
      FridayPrayerReminderPlanner(ref.watch(notificationServiceProvider)),
);

final Provider<PrayerCoordinator> prayerCoordinatorProvider =
    Provider<PrayerCoordinator>(
      (Ref ref) => PrayerCoordinator(
        ref.watch(prayerTimesRepositoryProvider),
        ref.watch(appDatabaseProvider),
        ref.watch(notificationServiceProvider),
        ref.watch(clockServiceProvider),
      ),
    );

final FutureProvider<PrayerDay?> todayPrayerDayProvider =
    FutureProvider<PrayerDay?>((Ref ref) async {
      final prefs = ref.watch(
        settingsControllerProvider.select(
          (prefs) => (
            location: prefs.location,
            prayerSettings: prefs.prayerSettings,
            localeCode: prefs.localeCode,
          ),
        ),
      );
      final location = prefs.location;
      if (location == null) {
        return null;
      }
      return ref
          .watch(prayerCoordinatorProvider)
          .loadToday(
            location: location,
            settings: prefs.prayerSettings,
            languageCode: prefs.localeCode,
          );
    });

final prayerByIdProvider = FutureProvider.family<PrayerEntry?, String>(
  (Ref ref, String id) => ref.watch(prayerCoordinatorProvider).prayerById(id),
);
