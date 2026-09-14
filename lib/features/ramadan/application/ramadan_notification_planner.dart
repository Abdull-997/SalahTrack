import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_calendar.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_settings.dart';

class RamadanNotificationPlanner {
  RamadanNotificationPlanner(this._notifications);

  final NotificationService _notifications;
  Future<void> _pendingReschedule = Future<void>.value();

  Future<void> reschedule(
    RamadanSettings settings,
    List<PrayerDay> days, {
    required DateTime nowUtc,
    required String languageCode,
  }) {
    final Future<void> result = _pendingReschedule.then(
      (_) => _reschedule(
        settings,
        days,
        nowUtc: nowUtc,
        languageCode: languageCode,
      ),
    );
    _pendingReschedule = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _reschedule(
    RamadanSettings settings,
    List<PrayerDay> days, {
    required DateTime nowUtc,
    required String languageCode,
  }) async {
    await _notifications.cancelAllRamadanNotifications();
    if (!settings.enabled ||
        days.isEmpty ||
        !RamadanCalendar.isRamadan(days.first) ||
        !await _notifications.notificationsAllowed()) {
      return;
    }

    for (final PrayerDay day in days) {
      if (!RamadanCalendar.isRamadan(day)) continue;
      final fajr = day.entries
          .where((entry) => entry.type == PrayerType.fajr)
          .firstOrNull;
      final maghrib = day.entries
          .where((entry) => entry.type == PrayerType.maghrib)
          .firstOrNull;
      if (settings.suhurReminderEnabled && fajr != null) {
        final DateTime reminderAt = fajr.scheduledAtUtc.subtract(
          Duration(minutes: settings.suhurReminderMinutes),
        );
        if (reminderAt.isAfter(nowUtc)) {
          await _notifications.scheduleRamadanReminder(
            kind: RamadanReminderKind.suhur,
            localDate: day.localDate,
            reminderAtUtc: reminderAt,
            timezoneId: day.timezoneId,
            minutesBefore: settings.suhurReminderMinutes,
            languageCode: languageCode,
          );
        }
      }
      if (settings.iftarReminderEnabled && maghrib != null) {
        final DateTime reminderAt = maghrib.scheduledAtUtc.subtract(
          Duration(minutes: settings.iftarReminderMinutes),
        );
        if (reminderAt.isAfter(nowUtc)) {
          await _notifications.scheduleRamadanReminder(
            kind: RamadanReminderKind.iftar,
            localDate: day.localDate,
            reminderAtUtc: reminderAt,
            timezoneId: day.timezoneId,
            minutesBefore: settings.iftarReminderMinutes,
            languageCode: languageCode,
          );
        }
      }
    }
  }
}
