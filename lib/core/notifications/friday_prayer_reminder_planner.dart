import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/core/time/timezone_service.dart';
import 'package:salah_focus/features/prayer_times/domain/friday_prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';

/// Owns the action-free reminder scheduled one hour before Jumu'ah.
///
/// Each refresh replaces every pending Friday reminder. Calculated Friday
/// Dhuhr entries are supplied by [PrayerCoordinator], so automatic mode stays
/// tied to the current location, calculation settings and timezone.
class FridayPrayerReminderPlanner {
  FridayPrayerReminderPlanner(this._notifications);

  final NotificationService _notifications;
  Future<void> _pendingReschedule = Future<void>.value();

  Future<void> reschedule(
    FridayPrayerSettings settings, {
    required List<PrayerEntry> fridayDhuhrEntries,
    required String languageCode,
    DateTime? nowUtc,
  }) {
    final Future<void> result = _pendingReschedule.then(
      (_) => _reschedule(
        settings,
        fridayDhuhrEntries: fridayDhuhrEntries,
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
    required List<PrayerEntry> fridayDhuhrEntries,
    required String languageCode,
    DateTime? nowUtc,
  }) async {
    await _notifications.cancelAllFridayPrayerNotifications();
    if (!settings.enabled ||
        fridayDhuhrEntries.isEmpty ||
        !await _notifications.notificationsAllowed()) {
      return;
    }

    final DateTime now = (nowUtc ?? DateTime.now()).toUtc();
    final Set<String> scheduledDates = <String>{};
    for (final PrayerEntry dhuhr in fridayDhuhrEntries) {
      if (!scheduledDates.add(dhuhr.localDate)) continue;
      final DateTime effectiveJumuahUtc = settings.usesDhuhrTime
          ? dhuhr.scheduledAtUtc
          : TimezoneService.localPartsToUtc(
              dateIso: dhuhr.localDate,
              hhmm: _hhmm(settings.manualMinutesFromMidnight!),
              timezoneId: dhuhr.timezoneId,
            );
      final DateTime reminderAtUtc = effectiveJumuahUtc.subtract(
        const Duration(hours: 1),
      );
      if (!reminderAtUtc.isAfter(now)) continue;
      await _notifications.scheduleFridayPrayerReminder(
        localDate: dhuhr.localDate,
        reminderAtUtc: reminderAtUtc,
        timezoneId: dhuhr.timezoneId,
        languageCode: languageCode,
      );
    }
  }

  static String _hhmm(int minutesFromMidnight) {
    final int hour = minutesFromMidnight ~/ 60;
    final int minute = minutesFromMidnight % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}
