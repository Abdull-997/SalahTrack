import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';

abstract interface class NotificationService {
  Stream<String> get payloads;

  Future<void> initialize();

  Future<String?> takeInitialPayload();

  Future<bool> requestPermission();

  Future<bool> notificationsAllowed();

  Future<bool> requestExactAlarmPermission();

  /// Opens the operating system page where the user can change this later.
  Future<void> openNotificationSettings();

  /// Opens the operating system page for precise alarm permission.
  Future<void> openExactAlarmSettings();

  Future<bool> canScheduleExactly();

  Future<bool> canUseFullScreenIntent();

  Future<bool> requestFullScreenIntentPermission();

  Future<void> openFullScreenIntentSettings();

  Future<void> schedulePrayer(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  });

  Future<void> scheduleGraceReminder(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  });

  Future<void> scheduleSnoozeReminder(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  });

  Future<void> scheduleSoftReminder(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  });

  Future<void> cancelPrayer(PrayerEntry prayer);

  Future<void> cancelAllFuturePrayerNotifications();
}
