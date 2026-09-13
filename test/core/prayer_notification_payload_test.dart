import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/core/notifications/prayer_notification_payload.dart';

void main() {
  const id = '2026-09-13:isha';

  test('versioned payload round trips prayer, action, and delivery identity', () {
    const payload = PrayerNotificationPayload(
      prayerId: id, kind: 'reminder',
      action: PrayerNotificationAction.snooze, eventId: '42:123456789',
    );
    final parsed = PrayerNotificationPayload.tryParse(payload.encode())!;
    expect(parsed.prayerId, id);
    expect(parsed.kind, 'reminder');
    expect(parsed.action, PrayerNotificationAction.snooze);
    expect(parsed.eventId, '42:123456789');
    final route = Uri.parse(parsed.routeLocation);
    expect(route.pathSegments, ['reminder', id]);
    expect(route.queryParameters, {'action': 'snooze', 'eventId': '42:123456789'});
  });

  for (final kind in ['prayer', 'reminder', 'soft']) {
    test('previously scheduled $kind payloads remain routable', () {
      final parsed = PrayerNotificationPayload.tryParse('$kind:$id')!;
      expect(parsed.prayerId, id);
      expect(parsed.kind, kind);
      expect(parsed.action, PrayerNotificationAction.open);
    });
  }

  test('actual action buttons override embedded action and body only opens', () {
    const payload = PrayerNotificationPayload(
      prayerId: id, action: PrayerNotificationAction.snooze, eventId: 'scheduled',
    );
    for (final actionId in [null, '', 'unexpected']) {
      expect(PrayerNotificationPayload.fromResponse(payload.encode(), actionId)!.action,
          PrayerNotificationAction.open);
    }
    final mark = PrayerNotificationPayload.fromResponse(payload.encode(), 'mark_prayed')!;
    expect(mark.action, PrayerNotificationAction.markPrayed);
    expect(mark.eventId, 'scheduled');
    final snooze = PrayerNotificationPayload.fromResponse('prayer:$id', 'snooze', eventId: 'response')!;
    expect(snooze.action, PrayerNotificationAction.snooze);
    expect(snooze.eventId, 'response');
  });

  test('untrusted malformed, oversized, or unsupported payloads are ignored', () {
    for (final invalid in <String?>[
      null, '', 'prayer:', 'reminder:../../settings', 'prayer:hello\n',
      'unknown:$id', '{', '[]', 'null',
      jsonEncode({'v': 2, 'prayerId': id, 'kind': 'prayer'}),
      jsonEncode({'v': 1, 'prayerId': 42, 'kind': 'prayer'}),
      jsonEncode({'v': 1, 'prayerId': id, 'kind': 'unknown'}),
      jsonEncode({'v': 1, 'prayerId': id, 'kind': 'prayer', 'action': 'delete'}),
      jsonEncode({'v': 1, 'prayerId': id, 'kind': 'prayer', 'action': 1}),
      jsonEncode({'v': 1, 'prayerId': id, 'kind': 'prayer', 'eventId': []}),
      jsonEncode({'v': 1, 'prayerId': id, 'kind': 'prayer', 'eventId': '\n'}),
      'prayer:${'x' * 2048}',
    ]) {
      expect(PrayerNotificationPayload.tryParse(invalid), isNull, reason: '$invalid');
    }
  });
}
