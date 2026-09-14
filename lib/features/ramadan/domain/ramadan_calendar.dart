import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';

class RamadanDate {
  const RamadanDate({required this.day, required this.year});

  final int day;
  final int year;
}

/// Reads the structured Hijri calendar values supplied with the same local
/// prayer-time calendar used by the rest of the app.
class RamadanCalendar {
  const RamadanCalendar._();

  static RamadanDate? dateFor(PrayerDay day) {
    if (day.hijriMonth == 9 && day.hijriDay != null && day.hijriYear != null) {
      return RamadanDate(day: day.hijriDay!, year: day.hijriYear!);
    }

    // Rows cached by releases before structured Hijri columns existed retain
    // the provider's English display value. This keeps offline upgrades useful
    // until the next monthly refresh writes the numeric values.
    final String? display = day.hijriDate;
    if (display == null || !display.toLowerCase().contains('rama')) return null;
    final List<int> numbers = RegExp(r'\d+')
        .allMatches(display)
        .map((Match match) => int.parse(match.group(0)!))
        .toList(growable: false);
    if (numbers.length < 2 || numbers.first < 1 || numbers.first > 30) {
      return null;
    }
    return RamadanDate(day: numbers.first, year: numbers.last);
  }

  static bool isRamadan(PrayerDay day) => dateFor(day) != null;
}
