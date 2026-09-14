import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/core/time/timezone_service.dart';
import 'package:salah_focus/features/prayer_times/domain/friday_prayer_settings.dart';

/// Owns the two weekly, reminder-only Friday Prayer notifications.
///
/// These reminders deliberately never create a prayer database entry and
/// therefore cannot enter the daily confirmation or tracking state machine.
class FridayPrayerReminderPlanner {
  FridayPrayerReminderPlanner(this._notifications);

  final NotificationService _notifications;
  Future<void> _pendingReschedule = Future<void>.value();

  Future<void> reschedule(
    FridayPrayerSettings settings, {
    required String timezoneId,
    required String languageCode,
    DateTime? nowUtc,
  }) {
    final Future<void> result = _pendingReschedule.then(
      (_) => _reschedule(
        settings,
        timezoneId: timezoneId,
        languageCode: languageCode,
        nowUtc: nowUtc,
      ),
    );
    _pendingReschedule = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _reschedule(
    FridayPrayerSettings settings, {
    required String timezoneId,
    required String languageCode,
    DateTime? nowUtc,
  }) async {
    await _notifications.cancelAllFridayPrayerNotifications();
    if (!settings.enabled || !await _notifications.notificationsAllowed()) {
      return;
    }

    final DateTime now = (nowUtc ?? DateTime.now()).toUtc();
    for (final int hoursBefore in <int>[2, 1]) {
      await _notifications.scheduleFridayPrayerReminder(
        firstReminderAtUtc: _nextReminderUtc(
          settings,
          hoursBefore: hoursBefore,
          timezoneId: timezoneId,
          nowUtc: now,
        ),
        timezoneId: timezoneId,
        hoursBefore: hoursBefore,
        languageCode: languageCode,
      );
    }
  }

  static DateTime _nextReminderUtc(
    FridayPrayerSettings settings, {
    required int hoursBefore,
    required String timezoneId,
    required DateTime nowUtc,
  }) {
    final DateTime localNow = TimezoneService.toLocal(nowUtc, timezoneId);
    final DateTime localDate = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
    );
    final int daysUntilFriday =
        (DateTime.friday - localDate.weekday) % DateTime.daysPerWeek;
    DateTime fridayDate = localDate.add(Duration(days: daysUntilFriday));
    DateTime reminderUtc = _reminderOn(
      fridayDate,
      settings,
      hoursBefore: hoursBefore,
      timezoneId: timezoneId,
    );
    if (!reminderUtc.isAfter(nowUtc)) {
      fridayDate = fridayDate.add(const Duration(days: DateTime.daysPerWeek));
      reminderUtc = _reminderOn(
        fridayDate,
        settings,
        hoursBefore: hoursBefore,
        timezoneId: timezoneId,
      );
    }
    return reminderUtc;
  }

  static DateTime _reminderOn(
    DateTime fridayDate,
    FridayPrayerSettings settings, {
    required int hoursBefore,
    required String timezoneId,
  }) => TimezoneService.localPartsToUtc(
    dateIso:
        '${fridayDate.year.toString().padLeft(4, '0')}-'
        '${fridayDate.month.toString().padLeft(2, '0')}-'
        '${fridayDate.day.toString().padLeft(2, '0')}',
    hhmm: settings.hhmm,
    timezoneId: timezoneId,
  ).subtract(Duration(hours: hoursBefore));
}
