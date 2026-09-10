import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:salah_focus/core/notifications/notification_ids.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/core/time/timezone_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const MethodChannel _settingsChannel = MethodChannel(
    'salah_focus/system_settings',
  );
  final StreamController<String> _payloadController =
      StreamController<String>.broadcast();
  bool _initialized = false;
  String? _initialPayload;

  @override
  Stream<String> get payloads => _payloadController.stream;

  static const AndroidNotificationDetails _androidPrayerDetails =
      AndroidNotificationDetails(
        'prayer_times',
        'Prayer times',
        channelDescription: 'Prayer-time reminders',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      );

  static const AndroidNotificationDetails _androidReminderDetails =
      AndroidNotificationDetails(
        'prayer_reminders',
        'Prayer reminders',
        channelDescription: 'Grace-period and snooze reminders',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      );

  static const DarwinNotificationDetails _darwinDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      );

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _payloadController.add(payload);
        }
      },
    );
    final NotificationAppLaunchDetails? launchDetails = await _plugin
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _initialPayload = launchDetails?.notificationResponse?.payload;
    }
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          'prayer_times',
          'Prayer times',
          description: 'Prayer-time reminders',
          importance: Importance.high,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          'prayer_reminders',
          'Prayer reminders',
          description: 'Grace-period and snooze reminders',
          importance: Importance.high,
        ),
      );
    }
    _initialized = true;
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
      await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
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
  Future<void> openNotificationSettings() async {
    if (Platform.isAndroid) {
      await _settingsChannel.invokeMethod<void>('openNotificationSettings');
      return;
    }
    await requestPermission();
  }

  @override
  Future<void> openExactAlarmSettings() async {
    if (Platform.isAndroid) {
      await _settingsChannel.invokeMethod<void>('openExactAlarmSettings');
      return;
    }
    await requestExactAlarmPermission();
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
      details: const NotificationDetails(
        android: _androidPrayerDetails,
        iOS: _darwinDetails,
      ),
      payload: 'prayer:${prayer.id}',
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
      details: const NotificationDetails(
        android: _androidReminderDetails,
        iOS: _darwinDetails,
      ),
      payload: 'reminder:${prayer.id}',
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
    await _schedule(
      id: NotificationIds.snooze(prayer),
      whenUtc: when,
      timezoneId: prayer.timezoneId,
      title: _text(languageCode, 'snoozeTitle', prayerName),
      body: _text(languageCode, 'snoozeBody', prayerName),
      details: const NotificationDetails(
        android: _androidReminderDetails,
        iOS: _darwinDetails,
      ),
      payload: 'reminder:${prayer.id}',
    );
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
      details: const NotificationDetails(
        android: _androidReminderDetails,
        iOS: _darwinDetails,
      ),
      payload: 'soft:${prayer.id}',
    );
  }

  Future<void> _schedule({
    required int id,
    required DateTime whenUtc,
    required String timezoneId,
    required String title,
    required String body,
    required NotificationDetails details,
    required String payload,
  }) async {
    await initialize();
    if (!await notificationsAllowed()) return;
    final DateTime now = DateTime.now().toUtc();
    if (!whenUtc.isAfter(now)) {
      return;
    }
    final tz.Location location = TimezoneService.locationOrUtc(timezoneId);
    final tz.TZDateTime scheduled = tz.TZDateTime.from(whenUtc, location);
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
      payload: payload,
    );
  }

  static String _text(String languageCode, String key, String prayerName) {
    const Map<String, Map<String, String>>
    values = <String, Map<String, String>>{
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
    await _plugin.cancel(id: NotificationIds.soft(prayer));
  }

  @override
  Future<void> cancelAllFuturePrayerNotifications() async {
    await initialize();
    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();
    for (final PendingNotificationRequest request in pending) {
      final String payload = request.payload ?? '';
      if (payload.startsWith('prayer:') || payload.startsWith('reminder:')) {
        await _plugin.cancel(id: request.id);
      }
    }
  }
}
