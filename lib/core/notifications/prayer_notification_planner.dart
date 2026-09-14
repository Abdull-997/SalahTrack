import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';

class PrayerNotificationPlanner {
  PrayerNotificationPlanner(this._notifications);

  final NotificationService _notifications;

  Future<void> reschedule(
    List<PrayerEntry> entries, {
    required String Function(PrayerEntry entry) prayerName,
    required String languageCode,
    DateTime? nowUtc,
    int horizonDays = 4,
  }) async {
    final DateTime now = (nowUtc ?? DateTime.now()).toUtc();
    final DateTime horizon = now.add(Duration(days: horizonDays));
    if (!await _notifications.notificationsAllowed()) return;
    await _notifications.cancelAllFuturePrayerNotifications();
    final Map<String, PrayerEntry> entriesByDateAndType = <String, PrayerEntry>{
      for (final PrayerEntry entry in entries)
        '${entry.localDate}:${entry.type.name}': entry,
    };
    for (final PrayerEntry entry in entries) {
      if (entry.status == PrayerStatus.prayed ||
          entry.status == PrayerStatus.skipped ||
          entry.status == PrayerStatus.missed) {
        continue;
      }
      final bool hasActiveSnooze =
          entry.status == PrayerStatus.snoozed &&
          entry.snoozedUntilUtc != null &&
          entry.snoozedUntilUtc!.isAfter(now);
      if (hasActiveSnooze) {
        await _notifications.scheduleSnoozeReminder(
          entry,
          prayerName(entry),
          languageCode: languageCode,
        );
      } else {
        if (entry.scheduledAtUtc.isAfter(now) &&
            entry.scheduledAtUtc.isBefore(horizon)) {
          await _notifications.schedulePrayer(
            entry,
            prayerName(entry),
            languageCode: languageCode,
          );
        }
        if (entry.graceEndsAtUtc.isAfter(now) &&
            entry.graceEndsAtUtc.isBefore(horizon)) {
          await _notifications.scheduleGraceReminder(
            entry,
            prayerName(entry),
            languageCode: languageCode,
          );
        }
      }

      final PrayerType? nextType = _oneHourReminderTargets[entry.type];
      final PrayerEntry? nextPrayer = nextType == null
          ? null
          : entriesByDateAndType['${entry.localDate}:${nextType.name}'];
      if (nextPrayer != null) {
        final DateTime reminderAt = nextPrayer.scheduledAtUtc.subtract(
          const Duration(hours: 1),
        );
        if (reminderAt.isAfter(now) && reminderAt.isBefore(horizon)) {
          await _notifications.scheduleOneHourRemainingReminder(
            entry,
            nextPrayer,
            prayerName(entry),
            prayerName(nextPrayer),
            languageCode: languageCode,
          );
        }
      }
    }
  }

  static const Map<PrayerType, PrayerType> _oneHourReminderTargets =
      <PrayerType, PrayerType>{
        PrayerType.dhuhr: PrayerType.asr,
        PrayerType.asr: PrayerType.maghrib,
        PrayerType.maghrib: PrayerType.isha,
      };
}
