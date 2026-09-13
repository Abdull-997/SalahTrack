import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/notifications/notification_ids.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/core/notifications/prayer_notification_payload.dart';
import 'package:salah_focus/core/time/timezone_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService implements NotificationService {
  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    String Function()? languageCode,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _languageCode = languageCode ?? (() => 'en') {
    _payloadController.onListen = () {
      scheduleMicrotask(() {
        while (_payloadController.hasListener && _bufferedPayloads.isNotEmpty) {
          _payloadController.add(_bufferedPayloads.removeAt(0));
        }
      });
    };
  }

  final FlutterLocalNotificationsPlugin _plugin;
  final String Function() _languageCode;
  String? _channelLanguage;
  static const MethodChannel _settingsChannel = MethodChannel(
    'salah_focus/system_settings',
  );
  final StreamController<String> _payloadController =
      StreamController<String>.broadcast();
  bool _initialized = false;
  Future<void>? _initializing;
  final List<String> _bufferedPayloads = <String>[];
  String? _initialPayload;

  @override
  Stream<String> get payloads => _payloadController.stream;

  static AndroidNotificationDetails _androidDetails(
    String languageCode, {
    bool reminder = false,
    bool soft = false,
  }) {
    final AppStrings s = AppStrings(Locale(languageCode));
    return AndroidNotificationDetails(
      soft ? 'prayer_reminders' : 'prayer_alarms_v2',
      s.t(reminder ? 'prayerReminders' : 'prayerTimes'),
      channelDescription: s.t('reminderBody'),
      importance: Importance.high,
      priority: Priority.high,
      category: soft
          ? AndroidNotificationCategory.reminder
          : AndroidNotificationCategory.alarm,
      fullScreenIntent: !soft,
      ongoing: !soft,
      autoCancel: soft,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: soft
          ? AudioAttributesUsage.notification
          : AudioAttributesUsage.alarm,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_prayed',
          s.t('markAsPrayed'),
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'snooze',
          s.t('snoozeAction'),
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );
  }

  static DarwinNotificationDetails _darwinDetails(String languageCode) =>
      DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'prayer_actions_$languageCode',
      );

  @override
  Future<void> initialize() async {
    if (_initializing != null) return _initializing;
    if (_initialized) {
      await _syncChannels();
      return;
    }
    final Future<void> initialization = _initialize();
    _initializing = initialization;
    try {
      await initialization;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    final InitializationSettings settings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: <DarwinNotificationCategory>[
          for (final Locale locale in AppStrings.supportedLocales)
            DarwinNotificationCategory(
              'prayer_actions_${locale.languageCode}',
              actions: <DarwinNotificationAction>[
                DarwinNotificationAction.plain(
                  'mark_prayed',
                  AppStrings(locale).t('markAsPrayed'),
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
                DarwinNotificationAction.plain(
                  'snooze',
                  AppStrings(locale).t('snoozeAction'),
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
              ],
            ),
        ],
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = _responsePayload(response);
        if (payload != null) {
          if (_payloadController.hasListener) {
            _payloadController.add(payload);
          } else {
            _bufferedPayloads.add(payload);
          }
        }
      },
    );
    final NotificationAppLaunchDetails? launchDetails = await _plugin
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final NotificationResponse? response =
          launchDetails?.notificationResponse;
      if (response != null) _initialPayload = _responsePayload(response);
    }
    _initialized = true;
    await _syncChannels();
  }

  static String? _responsePayload(NotificationResponse response) {
    if (response.notificationResponseType ==
        NotificationResponseType.notificationDismissed) {
      return null;
    }
    return PrayerNotificationPayload.fromResponse(
      response.payload,
      response.actionId,
    )?.encode();
  }

  Future<void> _syncChannels() async {
    final String languageCode = _languageCode();
    if (Platform.isAndroid && _channelLanguage != languageCode) {
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      for (final bool soft in <bool>[false, true]) {
        final AndroidNotificationDetails details = _androidDetails(
          languageCode,
          reminder: true,
          soft: soft,
        );
        await android?.createNotificationChannel(
          AndroidNotificationChannel(
            details.channelId,
            details.channelName,
            description: details.channelDescription,
            importance: Importance.high,
            audioAttributesUsage: details.audioAttributesUsage,
          ),
        );
      }
      _channelLanguage = languageCode;
    }
  }

  @override
  Future<String?> takeInitialPayload() async {
    await initialize();
    final String? payload = _initialPayload;
    _initialPayload = null;
    return payload;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
      return notificationsAllowed();
    }
    if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return notificationsAllowed();
    }
    return true;
  }

  @override
  Future<bool> notificationsAllowed() async {
    await initialize();
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? false;
    }
    if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final NotificationsEnabledOptions? permissions = await ios
          ?.checkPermissions();
      return permissions?.isEnabled ?? false;
    }
    return true;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    await initialize();
    if (!Platform.isAndroid) {
      return true;
    }
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestExactAlarmsPermission() ?? false;
  }

  @override
  Future<void> openNotificationSettings() =>
      _openSettings('openNotificationSettings');

  @override
  Future<void> openExactAlarmSettings() =>
      _openSettings('openExactAlarmSettings');

  @override
  Future<void> openFullScreenIntentSettings() =>
      _openSettings('openFullScreenIntentSettings');

  @override
  Future<bool> canUseFullScreenIntent() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      return await _settingsChannel.invokeMethod<bool>(
            'canUseFullScreenIntent',
          ) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> requestFullScreenIntentPermission() async {
    await initialize();
    if (!Platform.isAndroid) return true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestFullScreenIntentPermission() ?? false;
  }

  Future<void> _openSettings(String method) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _settingsChannel.invokeMethod<void>(method);
        return;
      } on MissingPluginException {
        // Older installed builds may not have the custom settings bridge.
      } on PlatformException {
        // Fall back to app details if a device cannot open the specific page.
      }
    }
    // This plugin is already registered on both mobile platforms. On iOS it
    // opens the app's settings even when permission was previously denied.
    if (!await Geolocator.openAppSettings()) {
      throw PlatformException(
        code: 'settings_unavailable',
        message: 'Unable to open app settings.',
      );
    }
  }

  @override
  Future<bool> canScheduleExactly() async {
    if (!Platform.isAndroid) {
      return true;
    }
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<void> schedulePrayer(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  }) async {
    await _schedule(
      id: NotificationIds.prayer(prayer),
      whenUtc: prayer.scheduledAtUtc,
      timezoneId: prayer.timezoneId,
      title: _text(languageCode, 'prayerTitle', prayerName),
      body: _text(languageCode, 'prayerBody', prayerName),
      details: NotificationDetails(
        android: _androidDetails(languageCode),
        iOS: _darwinDetails(languageCode),
      ),
      payload: PrayerNotificationPayload(prayerId: prayer.id).encode(),
    );
  }

  @override
  Future<void> scheduleGraceReminder(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  }) async {
    await _schedule(
      id: NotificationIds.grace(prayer),
      whenUtc: prayer.graceEndsAtUtc,
      timezoneId: prayer.timezoneId,
      title: _text(languageCode, 'graceTitle', prayerName),
      body: _text(languageCode, 'graceBody', prayerName),
      details: NotificationDetails(
        android: _androidDetails(languageCode, reminder: true),
        iOS: _darwinDetails(languageCode),
      ),
      payload: PrayerNotificationPayload(
        prayerId: prayer.id,
        kind: 'reminder',
      ).encode(),
    );
  }

  @override
  Future<void> scheduleSnoozeReminder(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  }) async {
    final DateTime? when = prayer.snoozedUntilUtc;
    if (when == null) {
      return;
    }
    final bool scheduled = await _schedule(
      id: NotificationIds.snooze(prayer),
      whenUtc: when,
      timezoneId: prayer.timezoneId,
      title: _text(languageCode, 'snoozeTitle', prayerName),
      body: _text(languageCode, 'snoozeBody', prayerName),
      details: NotificationDetails(
        android: _androidDetails(languageCode, reminder: true),
        iOS: _darwinDetails(languageCode),
      ),
      payload: PrayerNotificationPayload(
        prayerId: prayer.id,
        kind: 'snooze',
      ).encode(),
    );
    if (!scheduled) {
      throw StateError('The snooze reminder could not be scheduled.');
    }
    // Keep the current alert until its replacement has been accepted by the OS.
    await _plugin.cancel(id: NotificationIds.prayer(prayer));
    await _plugin.cancel(id: NotificationIds.grace(prayer));
    await _plugin.cancel(id: NotificationIds.soft(prayer));
    await _plugin.cancel(id: NotificationIds.previousSnooze(prayer));
  }

  @override
  Future<void> scheduleSoftReminder(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  }) async {
    final DateTime candidate = DateTime.now().toUtc().add(
      const Duration(minutes: 45),
    );
    if (!candidate.isBefore(prayer.trackingEndsAtUtc)) {
      return;
    }
    await _schedule(
      id: NotificationIds.soft(prayer),
      whenUtc: candidate,
      timezoneId: prayer.timezoneId,
      title: _text(languageCode, 'softTitle', prayerName),
      body: _text(languageCode, 'softBody', prayerName),
      details: NotificationDetails(
        android: _androidDetails(languageCode, reminder: true, soft: true),
        iOS: _darwinDetails(languageCode),
      ),
      payload: PrayerNotificationPayload(
        prayerId: prayer.id,
        kind: 'soft',
      ).encode(),
    );
  }

  Future<bool> _schedule({
    required int id,
    required DateTime whenUtc,
    required String timezoneId,
    required String title,
    required String body,
    required NotificationDetails details,
    required String payload,
  }) async {
    await initialize();
    if (!await notificationsAllowed()) return false;
    final DateTime now = DateTime.now().toUtc();
    if (!whenUtc.isAfter(now)) {
      return false;
    }
    final tz.Location location = TimezoneService.locationOrUtc(timezoneId);
    // Native calendar triggers have whole-second precision. Rounding down can
    // deliver Snooze just before its stored deadline, leaving the reminder
    // screen in the still-snoozed state with its alarm flags disabled.
    const int second = Duration.microsecondsPerSecond;
    final DateTime scheduledUtc = DateTime.fromMicrosecondsSinceEpoch(
      ((whenUtc.microsecondsSinceEpoch + second - 1) ~/ second) * second,
      isUtc: true,
    );
    final tz.TZDateTime scheduled = tz.TZDateTime.from(scheduledUtc, location);
    final bool exact = await canScheduleExactly();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: PrayerNotificationPayload.fromResponse(
        payload,
        null,
        eventId: '$id:${whenUtc.microsecondsSinceEpoch}',
      )!.encode(),
    );
    return true;
  }

  static String _text(String languageCode, String key, String prayerName) {
    const Map<String, Map<String, String>>
    values = <String, Map<String, String>>{
      'fr': <String, String>{
        'prayerTitle': '🕌 C’est l’heure de {prayer}',
        'prayerBody': 'C’est l’heure de votre prière.',
        'graceTitle': 'L’heure de {prayer}',
        'graceBody': 'Vous souhaitiez consacrer quelques minutes à votre prière maintenant.',
        'snoozeTitle': '{prayer} – rappel',
        'snoozeBody': 'Le délai de report est terminé. Prenez quelques minutes si vous le pouvez.',
        'softTitle': 'Un petit rappel 🤍',
        'softBody': 'Prenez quelques minutes pour {prayer}, si vous le pouvez.',
      },
      'es': <String, String>{
        'prayerTitle': '🕌 Es la hora de {prayer}',
        'prayerBody': 'Es la hora de tu oración.',
        'graceTitle': 'Hora de {prayer}',
        'graceBody': 'Querías dedicar unos minutos a tu oración ahora.',
        'snoozeTitle': '{prayer} – recordatorio',
        'snoozeBody':
            'El aplazamiento ha terminado. Dedica unos minutos si puedes.',
        'softTitle': 'Un pequeño recordatorio 🤍',
        'softBody': 'Dedica unos minutos a {prayer}, si puedes.',
      },
      'tr': <String, String>{
        'prayerTitle': '🕌 {prayer} vakti geldi',
        'prayerBody': 'Namaz vakti geldi.',
        'graceTitle': '{prayer} vakti',
        'graceBody': 'Şimdi namazın için birkaç dakika ayırmak istemiştin.',
        'snoozeTitle': '{prayer} – hatırlatma',
        'snoozeBody': 'Erteleme süresi bitti. Müsaitsen birkaç dakika ayır.',
        'softTitle': 'Nazik bir hatırlatma 🤍',
        'softBody': 'Müsaitsen {prayer} için birkaç dakika ayır.',
      },
      'de': <String, String>{
        'prayerTitle': '🕌 {prayer} ist da',
        'prayerBody': 'Es ist Zeit für dein Gebet.',
        'graceTitle': 'Zeit für {prayer}',
        'graceBody':
            'Du wolltest dir jetzt ein paar Minuten für dein Gebet nehmen.',
        'snoozeTitle': '{prayer} – Erinnerung',
        'snoozeBody':
            'Deine Snooze-Zeit ist vorbei. Nimm dir Zeit, wenn du kannst.',
        'softTitle': 'Eine kleine Erinnerung 🤍',
        'softBody': 'Nimm dir ein paar Minuten für {prayer}, wenn du kannst.',
      },
      'en': <String, String>{
        'prayerTitle': '🕌 {prayer} is here',
        'prayerBody': 'It is time for your prayer.',
        'graceTitle': 'Time for {prayer}',
        'graceBody': 'You wanted to make a few minutes for your prayer now.',
        'snoozeTitle': '{prayer} – reminder',
        'snoozeBody': 'Your snooze has ended. Take a few minutes if you can.',
        'softTitle': 'A gentle reminder 🤍',
        'softBody': 'Take a few minutes for {prayer}, if you can.',
      },
      'ar': <String, String>{
        'prayerTitle': '🕌 حان وقت {prayer}',
        'prayerBody': 'حان وقت الصلاة.',
        'graceTitle': 'وقت {prayer}',
        'graceBody': 'أردت أن تخصص الآن بضع دقائق لصلاتك.',
        'snoozeTitle': 'تذكير {prayer}',
        'snoozeBody': 'انتهى وقت التأجيل. خذ بضع دقائق إن استطعت.',
        'softTitle': 'تذكير لطيف 🤍',
        'softBody': 'خذ بضع دقائق من أجل {prayer} إن استطعت.',
      },
      'ur': <String, String>{
        'prayerTitle': '🕌 {prayer} کا وقت ہو گیا',
        'prayerBody': 'آپ کی نماز کا وقت ہے۔',
        'graceTitle': '{prayer} کا وقت',
        'graceBody':
            'آپ نے ابھی اپنی نماز کے لیے چند منٹ نکالنے کا ارادہ کیا تھا۔',
        'snoozeTitle': '{prayer} – یاد دہانی',
        'snoozeBody':
            'موخر کرنے کا وقت ختم ہو گیا ہے۔ اگر ممکن ہو تو چند منٹ نکالیں۔',
        'softTitle': 'نرم یاد دہانی 🤍',
        'softBody': 'اگر ممکن ہو تو {prayer} کے لیے چند منٹ نکالیں۔',
      },
      'ps': <String, String>{
        'prayerTitle': '🕌 د {prayer} وخت شو',
        'prayerBody': 'ستاسو د لمانځه وخت دی.',
        'graceTitle': 'د {prayer} وخت',
        'graceBody': 'تاسو غوښتل اوس خپل لمانځه ته څو دقیقې ځانګړې کړئ.',
        'snoozeTitle': '{prayer} – یادونه',
        'snoozeBody': 'د ځنډ وخت پای ته ورسېد. که کولی شئ، څو دقیقې وخت واخلئ.',
        'softTitle': 'نرمه یادونه 🤍',
        'softBody': 'که کولی شئ، د {prayer} لپاره څو دقیقې وخت واخلئ.',
      },
    };
    return (values[languageCode]?[key] ?? values['en']![key] ?? key).replaceAll(
      '{prayer}',
      prayerName,
    );
  }

  @override
  Future<void> cancelPrayer(PrayerEntry prayer) async {
    await initialize();
    await _plugin.cancel(id: NotificationIds.prayer(prayer));
    await _plugin.cancel(id: NotificationIds.grace(prayer));
    await _plugin.cancel(id: NotificationIds.snooze(prayer));
    await _plugin.cancel(id: NotificationIds.previousSnooze(prayer));
    await _plugin.cancel(id: NotificationIds.soft(prayer));
  }

  @override
  Future<void> cancelAllFuturePrayerNotifications() async {
    await initialize();
    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();
    for (final PendingNotificationRequest request in pending) {
      final String payload = request.payload ?? '';
      final parsed = PrayerNotificationPayload.tryParse(payload);
      // Soft reminders are one-off opt-ins after skipping, not planner entries.
      if (parsed != null && parsed.kind != 'soft') {
        await _plugin.cancel(id: request.id);
      }
    }
  }
}
