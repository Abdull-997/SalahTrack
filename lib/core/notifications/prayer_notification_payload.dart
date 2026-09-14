import 'dart:convert';

enum PrayerNotificationAction {
  open,
  markPrayed,
  snooze;

  String get value => switch (this) {
    open => 'open',
    markPrayed => 'mark_prayed',
    snooze => 'snooze',
  };

  static PrayerNotificationAction? tryParse(String? value) => switch (value) {
    'open' => open,
    'mark_prayed' => markPrayed,
    'snooze' => snooze,
    _ => null,
  };
}

/// The shared contract for scheduled notifications and their responses.
class PrayerNotificationPayload {
  const PrayerNotificationPayload({
    required this.prayerId,
    this.kind = 'prayer',
    this.action = PrayerNotificationAction.open,
    this.eventId,
  });

  final String prayerId;
  final String kind;
  final PrayerNotificationAction action;
  final String? eventId;

  String encode() => jsonEncode(<String, Object>{
    'v': 1,
    'prayerId': prayerId,
    'kind': kind,
    'action': action.value,
    'eventId': ?eventId,
  });

  String get routeLocation =>
      <String>{'fridayPrayer', 'oneHourRemaining'}.contains(kind)
      ? '/home'
      : Uri(
          pathSegments: <String>['', 'reminder', prayerId],
          queryParameters: <String, String>{
            'action': action.value,
            'eventId': ?eventId,
          },
        ).toString();

  static final RegExp _identifier = RegExp(
    r'^[a-zA-Z0-9][a-zA-Z0-9:_-]{0,199}$',
  );
  static final RegExp _controlCharacters = RegExp(r'[\x00-\x1f\x7f]');
  static const Set<String> _kinds = <String>{
    'prayer',
    'reminder',
    'snooze',
    'soft',
    'oneHourRemaining',
    'fridayPrayer',
  };

  static PrayerNotificationPayload? tryParse(String? payload) {
    if (payload == null || payload.isEmpty || payload.length > 2048) {
      return null;
    }
    for (final String kind in <String>['prayer', 'reminder', 'soft']) {
      final String prefix = '$kind:';
      if (payload.startsWith(prefix)) {
        final String prayerId = payload.substring(prefix.length);
        return _identifier.hasMatch(prayerId)
            ? PrayerNotificationPayload(prayerId: prayerId, kind: kind)
            : null;
      }
    }
    try {
      final Object? data = jsonDecode(payload);
      if (data is! Map<String, dynamic> || data['v'] != 1) return null;
      final Object? prayerId = data['prayerId'];
      final Object? kind = data['kind'];
      final Object? rawAction = data['action'] ?? 'open';
      final Object? eventId = data['eventId'];
      if (prayerId is! String ||
          !_identifier.hasMatch(prayerId) ||
          kind is! String ||
          !_kinds.contains(kind) ||
          rawAction is! String) {
        return null;
      }
      final PrayerNotificationAction? action =
          PrayerNotificationAction.tryParse(rawAction);
      if (action == null) return null;
      if (eventId != null &&
          (eventId is! String ||
              eventId.isEmpty ||
              eventId.length > 256 ||
              _controlCharacters.hasMatch(eventId))) {
        return null;
      }
      return PrayerNotificationPayload(
        prayerId: prayerId,
        kind: kind,
        action: action,
        eventId: eventId as String?,
      );
    } on FormatException {
      return null;
    }
  }

  /// The actual button, rather than an embedded scheduled action, is authoritative.
  static PrayerNotificationPayload? fromResponse(
    String? payload,
    String? actionId, {
    String? eventId,
  }) {
    final PrayerNotificationPayload? parsed = tryParse(payload);
    if (parsed == null) return null;
    return PrayerNotificationPayload(
      prayerId: parsed.prayerId,
      kind: parsed.kind,
      action:
          PrayerNotificationAction.tryParse(actionId) ??
          PrayerNotificationAction.open,
      eventId: eventId ?? parsed.eventId,
    );
  }
}
