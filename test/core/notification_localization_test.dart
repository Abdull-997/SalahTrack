import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/core/notifications/local_notification_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:timezone/timezone.dart';

class _Plugin implements FlutterLocalNotificationsPlugin {
  final List<
    ({
      String? title,
      String? body,
      NotificationDetails details,
      String? payload,
    })
  >
  scheduled = [];

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async => true;

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async => null;

  @override
  Future<void> zonedSchedule({
    required int id,
    required TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduled.add((
      title: title,
      body: body,
      details: notificationDetails,
      payload: payload,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final String code in ['tr', 'fr', 'es']) {
    test(
      '$code localizes every scheduled reminder and Android channel',
      () async {
        final _Plugin plugin = _Plugin();
        final LocalNotificationService service = LocalNotificationService(
          plugin: plugin,
          languageCode: () => code,
        );
        final DateTime later = DateTime.now().toUtc().add(
          const Duration(hours: 2),
        );
        final PrayerEntry entry = PrayerEntry(
          id: 'test-isha',
          localDate: later.toIso8601String().substring(0, 10),
          type: PrayerType.isha,
          scheduledAtUtc: later,
          timezoneId: 'UTC',
          graceEndsAtUtc: later.add(const Duration(hours: 1)),
          trackingEndsAtUtc: later.add(const Duration(hours: 2)),
          snoozedUntilUtc: later,
          status: PrayerStatus.snoozed,
        );
        final String name = entry.type.localizedName(code);
        await service.schedulePrayer(entry, name, languageCode: code);
        await service.scheduleGraceReminder(entry, name, languageCode: code);
        await service.scheduleSnoozeReminder(entry, name, languageCode: code);
        await service.scheduleSoftReminder(entry, name, languageCode: code);
        expect(plugin.scheduled, hasLength(4));
        final List<String> titles = switch (code) {
          'tr' => [
            '🕌 Yatsı vakti geldi',
            'Yatsı vakti',
            'Yatsı – hatırlatma',
            'Nazik bir hatırlatma 🤍',
          ],
          'fr' => [
            '🕌 C’est l’heure de Icha',
            'L’heure de Icha',
            'Icha – rappel',
            'Un petit rappel 🤍',
          ],
          _ => [
            '🕌 Es la hora de Isha',
            'Hora de Isha',
            'Isha – recordatorio',
            'Un pequeño recordatorio 🤍',
          ],
        };
        expect(plugin.scheduled.map((item) => item.title), titles);
        final String channelName = switch (code) {
          'tr' => 'Namaz hatırlatmaları',
          'fr' => 'Rappels de prière',
          _ => 'Recordatorios de oración',
        };
        expect(plugin.scheduled[1].details.android!.channelName, channelName);
        expect(
          plugin.scheduled[1].details.android!.channelId,
          'prayer_reminders',
        );
        for (final item in plugin.scheduled) {
          expect(item.body, isNotEmpty);
          expect(item.body, isNot(contains('your')));
          expect(item.body, isNot(contains('{prayer}')));
        }
        expect(plugin.scheduled.last.payload, 'soft:test-isha');
      },
    );
  }
}
