import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';

enum RamadanReminderKind { suhur, iftar }

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

  /// Schedules the action-free reminder one hour before the next prayer.
  Future<void> scheduleOneHourRemainingReminder(
    PrayerEntry prayer,
    PrayerEntry nextPrayer,
    String prayerName,
    String nextPrayerName, {
    required String languageCode,
  });

  /// Schedules one action-free reminder for a specific Friday.
  Future<void> scheduleFridayPrayerReminder({
    required String localDate,
    required DateTime reminderAtUtc,
    required String timezoneId,
    required String languageCode,
  });

  Future<void> cancelPrayer(PrayerEntry prayer);

  Future<void> cancelAllFuturePrayerNotifications();

  Future<void> cancelAllFridayPrayerNotifications();

  /// Schedules a normal, action-free Ramadan information reminder.
  Future<void> scheduleRamadanReminder({
    required RamadanReminderKind kind,
    required String localDate,
    required DateTime reminderAtUtc,
    required String timezoneId,
    required int minutesBefore,
    required String languageCode,
  });

  Future<void> cancelAllRamadanNotifications();
}
