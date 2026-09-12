import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/core/database/app_database.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/core/time/clock_service.dart';
import 'package:salah_focus/features/prayer_times/application/prayer_coordinator.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_times_repository.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/data/latest.dart' as tz;

class _MemoryDatabase implements Database, Transaction {
  final rows = <String, Map<String, Object?>>{};

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction) action, {
    bool? exclusive,
  }) => action(this);

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    rows[values['id']! as String] = Map.of(values);
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final row = rows[whereArgs!.first];
    return row == null
        ? []
        : [
            if (columns == null)
              Map.of(row)
            else
              {for (final column in columns) column: row[column]},
          ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements PrayerTimesRepository {
  _Repository(this.database);
  final AppDatabase database;

  @override
  Future<void> saveEntry(PrayerEntry entry) =>
      database.upsertPrayerEntry(entry);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Clock implements ClockService {
  DateTime now = DateTime.utc(2026, 9, 12, 23, 30);

  @override
  DateTime nowUtc() => now;
}

class _Notifications implements NotificationService {
  @override
  Future<void> cancelPrayer(PrayerEntry prayer) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PrayerEntry _entry(String date) => PrayerEntry(
  id: '$date-fajr',
  localDate: date,
  type: PrayerType.fajr,
  scheduledAtUtc: DateTime.parse('${date}T03:00:00Z'),
  timezoneId: 'Europe/Berlin',
  graceEndsAtUtc: DateTime.parse('${date}T04:00:00Z'),
  trackingEndsAtUtc: DateTime.parse('${date}T10:00:00Z'),
  status: PrayerStatus.missed,
);

void main() {
  setUpAll(tz.initializeTimeZones);

  test('older records do not acquire an edited indicator', () {
    final row = _entry('2026-09-12').toMap()..remove('edited_at_utc');
    expect(PrayerEntry.fromMap(row).editedAtUtc, isNull);
  });

  test(
    'past-day corrections persist after reads, undo, and schedule refresh',
    () async {
      final db = AppDatabase(_MemoryDatabase());
      final clock = _Clock();
      final coordinator = PrayerCoordinator(
        _Repository(db),
        db,
        _Notifications(),
        clock,
      );
      // It is already September 13 in Berlin, although UTC is September 12.
      final original = _entry('2026-09-12');
      await coordinator.correctHistoricalPrayer(original, prayed: true);
      final prayed = (await db.prayerEntryById(original.id))!;
      expect(prayed.status, PrayerStatus.prayed);
      expect(prayed.editedAtUtc, clock.now);
      expect(prayed.confirmedAtUtc, clock.now);

      await db.upsertPrayerEntries([
        original.copyWith(status: PrayerStatus.upcoming),
      ]);
      final refreshed = (await db.prayerEntryById(original.id))!;
      expect(refreshed.status, PrayerStatus.prayed);
      expect(refreshed.editedAtUtc, clock.now);

      clock.now = clock.now.add(const Duration(minutes: 5));
      await coordinator.correctHistoricalPrayer(refreshed, prayed: false);
      await db.upsertPrayerEntries([original]);
      final undone = (await db.prayerEntryById(original.id))!;
      expect(undone.status, PrayerStatus.missed);
      expect(undone.confirmedAtUtc, isNull);
      expect(undone.editedAtUtc, clock.now);
      expect(undone.copyWith(manualOffsetMinutes: 5).editedAtUtc, clock.now);
    },
  );

  test('same-day changes use the prayer timezone and stay unmarked', () async {
    final db = AppDatabase(_MemoryDatabase());
    final coordinator = PrayerCoordinator(
      _Repository(db),
      db,
      _Notifications(),
      _Clock(),
    );
    final today = _entry('2026-09-13');
    final prayed = await coordinator.correctHistoricalPrayer(
      today,
      prayed: true,
    );
    expect(prayed.editedAtUtc, isNull);
    final undone = await coordinator.correctHistoricalPrayer(
      prayed,
      prayed: false,
    );
    expect(undone.editedAtUtc, isNull);
    expect((await db.prayerEntryById(today.id))!.editedAtUtc, isNull);
  });
}
