import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';

/// A reminder rule for one prayer. An empty weekday set means every day.
class ReminderException {
  const ReminderException({
    required this.prayer,
    this.weekdays = const <int>{},
  });

  final PrayerType prayer;

  /// ISO weekdays, Monday = 1 through Sunday = 7.
  final Set<int> weekdays;

  bool get everyDay => weekdays.isEmpty;

  bool appliesTo(String localDate) {
    if (everyDay) return true;
    final DateTime? date = DateTime.tryParse(localDate);
    return date != null && weekdays.contains(date.weekday);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'prayer': prayer.name,
    'weekdays': weekdays.toList()..sort(),
  };

  static ReminderException? fromJson(Object? value) {
    if (value is! Map) return null;
    final Object? rawPrayer = value['prayer'];
    PrayerType? prayer;
    for (final PrayerType candidate in PrayerType.values) {
      if (candidate.name == rawPrayer) prayer = candidate;
    }
    if (prayer == null) return null;
    final Object? rawDays = value['weekdays'];
    if (rawDays is! List) return null;
    final Set<int> days = <int>{};
    for (final Object? raw in rawDays) {
      if (raw is! int || raw < 1 || raw > 7) return null;
      days.add(raw);
    }
    return ReminderException(prayer: prayer, weekdays: days);
  }
}
