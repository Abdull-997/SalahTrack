import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';

class NotificationIds {
  const NotificationIds._();

  static int prayer(PrayerEntry entry) => _base(entry) + 1;
  static int grace(PrayerEntry entry) => _base(entry) + 2;
  // Alternate slots so a replacement can be scheduled before dismissing the
  // delivered snooze, without cancelling the newly scheduled alarm.
  static int snooze(PrayerEntry entry) =>
      _base(entry) + (entry.snoozeCount.isEven ? 3 : 5);
  static int previousSnooze(PrayerEntry entry) =>
      _base(entry) + (entry.snoozeCount.isEven ? 5 : 3);
  static int soft(PrayerEntry entry) => _base(entry) + 4;

  static int fridayPrayer(int hoursBefore) =>
      1800000000 + (hoursBefore == 2 ? 1 : 2);

  static int _base(PrayerEntry entry) {
    final String compact = entry.localDate.replaceAll('-', '');
    final int date = int.tryParse(compact.substring(2)) ?? 0;
    return date * 100 + entry.type.index * 10;
  }
}
