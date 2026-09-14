import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_calendar.dart';

void main() {
  test('detects Ramadan from structured provider Hijri values', () {
    const PrayerDay day = PrayerDay(
      localDate: '2027-02-08',
      timezoneId: 'Europe/Berlin',
      entries: [],
      hijriDate: '1 Ramaḍān 1448',
      hijriDay: 1,
      hijriMonth: 9,
      hijriYear: 1448,
    );

    final RamadanDate? result = RamadanCalendar.dateFor(day);
    expect(result?.day, 1);
    expect(result?.year, 1448);
  });

  test('does not treat another Hijri month as Ramadan', () {
    const PrayerDay day = PrayerDay(
      localDate: '2026-09-14',
      timezoneId: 'Europe/Berlin',
      entries: [],
      hijriDate: '2 Rabīʿ al-thānī 1448',
      hijriDay: 2,
      hijriMonth: 4,
      hijriYear: 1448,
    );

    expect(RamadanCalendar.isRamadan(day), isFalse);
  });

  test('recognizes pre-migration cached Ramadan display values offline', () {
    const PrayerDay day = PrayerDay(
      localDate: '2027-02-19',
      timezoneId: 'Asia/Karachi',
      entries: [],
      hijriDate: '12 Ramadan 1448',
    );

    final RamadanDate? result = RamadanCalendar.dateFor(day);
    expect(result?.day, 12);
    expect(result?.year, 1448);
  });
}
