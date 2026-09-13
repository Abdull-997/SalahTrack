import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/core/database/app_database.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/core/time/clock_service.dart';
import 'package:salah_focus/features/prayer_times/application/prayer_coordinator.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_times_repository.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  late AppDatabase database;
  late _Clock clock;
  late _Notifications notifications;
  late PrayerCoordinator coordinator;
  late PrayerEntry original;
  const settings = PrayerSettings(snoozeMinutes: 20, maxSnoozes: 2);

  setUp(() async {
    database = AppDatabase(_MemoryDatabase());
    clock = _Clock();
    notifications = _Notifications();
    coordinator = PrayerCoordinator(
      _Repository(database),
      database,
      notifications,
      clock,
    );
    original = PrayerEntry(
      id: '2026-09-13:isha',
      localDate: '2026-09-13',
      type: PrayerType.isha,
      scheduledAtUtc: DateTime.utc(2026, 9, 13, 20),
      timezoneId: 'UTC',
      graceEndsAtUtc: DateTime.utc(2026, 9, 13, 20, 10),
      trackingEndsAtUtc: DateTime.utc(2026, 9, 14, 3),
      status: PrayerStatus.pending,
    );
    await database.upsertPrayerEntry(original);
  });

  test('concurrent snooze responses schedule once and consume one snooze', () async {
    final results = await Future.wait([
      coordinator.snooze(original, settings, 'Isha', 'en'),
      coordinator.snooze(original, settings, 'Isha', 'en'),
    ]);

    final stored = (await database.prayerEntryById(original.id))!;
    final until = clock.now.add(const Duration(minutes: 20));
    expect(stored.status, PrayerStatus.snoozed);
    expect(stored.snoozeCount, 1);
    expect(stored.snoozedUntilUtc, until);
    expect(results.map((entry) => entry.snoozedUntilUtc), [until, until]);
    expect(results.map((entry) => entry.snoozeCount), [1, 1]);
    expect(notifications.snoozeAttempts, 1);
    expect(notifications.scheduled.single.snoozedUntilUtc, until);
  });

  test('replayed confirmation preserves the first confirmation timestamp', () async {
    final confirmed = await coordinator.confirm(original);
    clock.now = clock.now.add(const Duration(minutes: 5));

    // A notification can replay its original, now stale prayer entry.
    final replayed = await coordinator.confirm(original);
    final stored = (await database.prayerEntryById(original.id))!;
    expect(replayed.status, PrayerStatus.prayed);
    expect(replayed.confirmedAtUtc, confirmed.confirmedAtUtc);
    expect(stored.confirmedAtUtc, confirmed.confirmedAtUtc);
    expect(notifications.cancelled, [original.id, original.id]);
    expect(notifications.activeSnoozes, isEmpty);
  });

  test('confirmation queued during snooze cancels its replacement', () async {
    final snoozing = coordinator.snooze(original, settings, 'Isha', 'en');
    final confirming = coordinator.confirm(original);
    await Future.wait([snoozing, confirming]);

    final stored = (await database.prayerEntryById(original.id))!;
    expect(stored.status, PrayerStatus.prayed);
    expect(stored.snoozedUntilUtc, isNull);
    expect(stored.snoozeCount, 1);
    expect(notifications.snoozeAttempts, 1);
    expect(notifications.activeSnoozes, isEmpty);
  });

  test('snooze queued during confirmation cannot reopen a prayed entry', () async {
    final confirming = coordinator.confirm(original);
    final snoozing = coordinator.snooze(original, settings, 'Isha', 'en');
    await expectLater(snoozing, throwsA(isA<StateError>()));
    await confirming;

    final stored = (await database.prayerEntryById(original.id))!;
    expect(stored.status, PrayerStatus.prayed);
    expect(stored.snoozedUntilUtc, isNull);
    expect(stored.snoozeCount, 0);
    expect(notifications.snoozeAttempts, 0);
    expect(notifications.activeSnoozes, isEmpty);
  });

  test('failed scheduling rolls back the snooze and permits a retry', () async {
    notifications.failNextSnooze = true;
    notifications.beforeSchedule = (entry) async {
      // Persist the replacement before dismissing the currently delivered alert.
      final stored = (await database.prayerEntryById(entry.id))!;
      expect(stored.status, PrayerStatus.snoozed);
      expect(stored.snoozedUntilUtc, entry.snoozedUntilUtc);
    };

    await expectLater(
      coordinator.snooze(original, settings, 'Isha', 'en'),
      throwsA(isA<StateError>()),
    );
    final failed = (await database.prayerEntryById(original.id))!;
    expect(failed.status, PrayerStatus.pending);
    expect(failed.snoozeCount, 0);
    expect(failed.snoozedUntilUtc, isNull);
    expect(notifications.scheduled, isEmpty);
    expect(notifications.cancelled, isEmpty);

    clock.now = clock.now.add(const Duration(minutes: 1));
    final retried = await coordinator.snooze(original, settings, 'Isha', 'en');
    final stored = (await database.prayerEntryById(original.id))!;
    expect(stored.status, PrayerStatus.snoozed);
    expect(stored.snoozeCount, 1);
    expect(stored.snoozedUntilUtc, clock.now.add(const Duration(minutes: 20)));
    expect(retried.snoozedUntilUtc, stored.snoozedUntilUtc);
    expect(notifications.snoozeAttempts, 2);
    expect(notifications.scheduled, hasLength(1));
  });
}

class _MemoryDatabase implements Database {
  final rows = <String, Map<String, Object?>>{};

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
    return row == null ? [] : [Map.of(row)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements PrayerTimesRepository {
  _Repository(this.database);
  final AppDatabase database;

  @override
  Future<void> saveEntry(PrayerEntry entry) => database.upsertPrayerEntry(entry);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Clock implements ClockService {
  DateTime now = DateTime.utc(2026, 9, 13, 20, 15);

  @override
  DateTime nowUtc() => now;
}

class _Notifications implements NotificationService {
  int snoozeAttempts = 0;
  bool failNextSnooze = false;
  Future<void> Function(PrayerEntry)? beforeSchedule;
  final scheduled = <PrayerEntry>[];
  final cancelled = <String>[];
  final activeSnoozes = <String>{};

  @override
  Future<void> scheduleSnoozeReminder(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  }) async {
    snoozeAttempts++;
    await beforeSchedule?.call(prayer);
    if (failNextSnooze) {
      failNextSnooze = false;
      throw StateError('The OS could not schedule the reminder.');
    }
    scheduled.add(prayer);
    activeSnoozes.add(prayer.id);
  }

  @override
  Future<void> cancelPrayer(PrayerEntry prayer) async {
    cancelled.add(prayer.id);
    activeSnoozes.remove(prayer.id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
