import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';

class PrayerDay {
  const PrayerDay({
    required this.localDate,
    required this.timezoneId,
    required this.entries,
    this.hijriDate,
    this.hijriDay,
    this.hijriMonth,
    this.hijriYear,
    this.sunriseUtc,
  });

  final String localDate;
  final String timezoneId;
  final List<PrayerEntry> entries;
  final String? hijriDate;
  final int? hijriDay;
  final int? hijriMonth;
  final int? hijriYear;
  final DateTime? sunriseUtc;

  PrayerDay copyWith({List<PrayerEntry>? entries}) => PrayerDay(
    localDate: localDate,
    timezoneId: timezoneId,
    entries: entries ?? this.entries,
    hijriDate: hijriDate,
    hijriDay: hijriDay,
    hijriMonth: hijriMonth,
    hijriYear: hijriYear,
    sunriseUtc: sunriseUtc,
  );
}
