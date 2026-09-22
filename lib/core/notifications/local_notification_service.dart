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
    'salahtrack/system_settings',
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
      'salahtrack_prayer_reminders_v1',
      s.t('prayerReminders'),
      channelDescription: s.t('reminderBody'),
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      ongoing: reminder && !soft,
      autoCancel: !reminder || soft,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.notification,
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

  static AndroidNotificationDetails _fridayPrayerAndroidDetails(
    String languageCode,
  ) => _actionFreePrayerReminderAndroidDetails(languageCode);

  static AndroidNotificationDetails _ramadanAndroidDetails(
    String languageCode,
  ) {
    final AppStrings s = AppStrings(Locale(languageCode));
    return AndroidNotificationDetails(
      'ramadan_reminders',
      s.t('ramadanNotifications'),
      channelDescription: s.t('ramadanNotificationsHelp'),
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      ongoing: false,
      autoCancel: true,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.notification,
      actions: const <AndroidNotificationAction>[],
    );
  }

  static AndroidNotificationDetails _actionFreePrayerReminderAndroidDetails(
    String languageCode,
  ) {
    final AppStrings s = AppStrings(Locale(languageCode));
    return AndroidNotificationDetails(
      'salahtrack_prayer_reminders_v1',
      s.t('prayerReminders'),
      channelDescription: s.t('reminderBody'),
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      ongoing: false,
      autoCancel: true,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.notification,
      actions: const <AndroidNotificationAction>[],
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

  static const DarwinNotificationDetails _actionFreeDarwinDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
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
      // These pre-release channels belonged to the retired alarm-style
      // presentation. Android persists channel settings, so never reuse them
      // for the production standard-notification architecture.
      for (final String obsoleteChannelId in <String>[
        'prayer_alarms_v2',
        'prayer_reminders',
        'friday_prayer_reminders',
      ]) {
        await android?.deleteNotificationChannel(channelId: obsoleteChannelId);
      }
      final AndroidNotificationDetails prayerDetails = _androidDetails(
        languageCode,
      );
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          prayerDetails.channelId,
          prayerDetails.channelName,
          description: prayerDetails.channelDescription,
          importance: Importance.high,
          audioAttributesUsage: prayerDetails.audioAttributesUsage,
          enableVibration: true,
        ),
      );
      final AndroidNotificationDetails ramadanDetails = _ramadanAndroidDetails(
        languageCode,
      );
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          ramadanDetails.channelId,
          ramadanDetails.channelName,
          description: ramadanDetails.channelDescription,
          importance: Importance.high,
          audioAttributesUsage: ramadanDetails.audioAttributesUsage,
        ),
      );
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

  @override
  Future<void> scheduleOneHourRemainingReminder(
    PrayerEntry prayer,
    PrayerEntry nextPrayer,
    String prayerName,
    String nextPrayerName, {
    required String languageCode,
  }) async {
    final AppStrings s = AppStrings(Locale(languageCode));
    await _schedule(
      id: NotificationIds.oneHourRemaining(prayer),
      whenUtc: nextPrayer.scheduledAtUtc.subtract(const Duration(hours: 1)),
      timezoneId: nextPrayer.timezoneId,
      title: s.t(
        'oneHourRemainingTitle',
        params: <String, String>{'prayer': prayerName},
      ),
      body: s.t(
        'oneHourRemainingBody',
        params: <String, String>{'nextPrayer': nextPrayerName},
      ),
      details: NotificationDetails(
        android: _actionFreePrayerReminderAndroidDetails(languageCode),
        iOS: _actionFreeDarwinDetails,
      ),
      payload: PrayerNotificationPayload(
        prayerId: prayer.id,
        kind: 'oneHourRemaining',
      ).encode(),
    );
  }

  @override
  Future<void> scheduleFridayPrayerReminder({
    required String localDate,
    required DateTime reminderAtUtc,
    required String timezoneId,
    required String languageCode,
  }) async {
    final AppStrings s = AppStrings(Locale(languageCode));
    await _schedule(
      id: NotificationIds.fridayPrayer(localDate),
      whenUtc: reminderAtUtc,
      timezoneId: timezoneId,
      title: s.t('fridayPrayer'),
      body: s.t('fridayPrayerInOneHour'),
      details: NotificationDetails(
        android: _fridayPrayerAndroidDetails(languageCode),
        iOS: _actionFreeDarwinDetails,
      ),
      payload: PrayerNotificationPayload(
        prayerId: 'friday-prayer-$localDate',
        kind: 'fridayPrayer',
      ).encode(),
    );
  }

  @override
  Future<void> scheduleRamadanReminder({
    required RamadanReminderKind kind,
    required String localDate,
    required DateTime reminderAtUtc,
    required String timezoneId,
    required int minutesBefore,
    required String languageCode,
  }) async {
    final AppStrings s = AppStrings(Locale(languageCode));
    final bool iftar = kind == RamadanReminderKind.iftar;
    await _schedule(
      id: NotificationIds.ramadan(localDate, iftar: iftar),
      whenUtc: reminderAtUtc,
      timezoneId: timezoneId,
      title: s.t(iftar ? 'iftar' : 'suhur'),
      body: s.t(
        iftar ? 'iftarReminderBody' : 'suhurReminderBody',
        params: <String, String>{'minutes': s.number(minutesBefore)},
      ),
      details: NotificationDetails(
        android: _ramadanAndroidDetails(languageCode),
        iOS: _actionFreeDarwinDetails,
      ),
      payload: 'ramadan|${kind.name}|$localDate',
      wrapPrayerPayload: false,
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
    DateTimeComponents? matchDateTimeComponents,
    bool wrapPrayerPayload = true,
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
      payload: wrapPrayerPayload
          ? PrayerNotificationPayload.fromResponse(
              payload,
              null,
              eventId: '$id:${whenUtc.microsecondsSinceEpoch}',
            )!.encode()
          : payload,
      matchDateTimeComponents: matchDateTimeComponents,
    );
    return true;
  }

  static String _text(String languageCode, String key, String prayerName) {
    const Map<String, Map<String, String>>
    values = <String, Map<String, String>>{
      'id': <String, String>{
        'prayerTitle': 'Azan {prayer}',
        'prayerBody': 'Waktu salat {prayer} telah tiba.',
        'graceTitle': 'Waktu {prayer}',
        'graceBody':
            'Anda ingin menyediakan beberapa menit untuk salat sekarang.',
        'snoozeTitle': '{prayer} – pengingat',
        'snoozeBody': 'Waktu penundaan telah berakhir. Luangkan beberapa menit jika Anda bisa.',
        'softTitle': 'Pengingat lembut 🤍',
        'softBody': 'Luangkan beberapa menit untuk {prayer}, jika Anda bisa.',
      },
      'bn': <String, String>{
        'prayerTitle': '{prayer} আজান',
        'prayerBody': '{prayer} নামাজের সময় শুরু হয়েছে।',
        'graceTitle': '{prayer}-এর সময়',
        'graceBody': 'আপনি এখন নামাজের জন্য কয়েক মিনিট রাখতে চেয়েছিলেন।',
        'snoozeTitle': '{prayer} – স্মরণিকা',
        'snoozeBody':
            'পরে মনে করানোর সময় শেষ হয়েছে। সম্ভব হলে কয়েক মিনিট সময় নিন।',
        'softTitle': 'একটি কোমল স্মরণিকা 🤍',
        'softBody': 'সম্ভব হলে {prayer}-এর জন্য কয়েক মিনিট সময় নিন।',
      },
      'pa': <String, String>{
        'prayerTitle': '{prayer} دی اذان',
        'prayerBody': '{prayer} دی نماز دا ویلا شروع ہو گیا اے۔',
        'graceTitle': '{prayer} دا ویلا',
        'graceBody': 'تسی ہن نماز لئی کجھ منٹ کڈھنا چاہیا سی۔',
        'snoozeTitle': '{prayer} – یاددہانی',
        'snoozeBody':
            'بعد وچ یاد کراؤن دا ویلا مک گیا اے۔ جے ہو سکے تے کجھ منٹ کڈھو۔',
        'softTitle': 'اک ہولی یاددہانی 🤍',
        'softBody': 'جے ہو سکے تے {prayer} لئی کجھ منٹ کڈھو۔',
      },
      'fa': <String, String>{
        'prayerTitle': 'اذان {prayer}',
        'prayerBody': 'وقت نماز {prayer} فرا رسیده است.',
        'graceTitle': 'وقت {prayer}',
        'graceBody': 'می‌خواستید اکنون چند دقیقه برای نماز وقت بگذارید.',
        'snoozeTitle': '{prayer} – یادآوری',
        'snoozeBody':
            'زمان تعویق پایان یافته است. اگر می‌توانید چند دقیقه وقت بگذارید.',
        'softTitle': 'یک یادآوری ملایم 🤍',
        'softBody': 'اگر می‌توانید چند دقیقه برای {prayer} وقت بگذارید.',
      },
      'ms': <String, String>{
        'prayerTitle': 'Azan {prayer}',
        'prayerBody': 'Waktu solat {prayer} telah bermula.',
        'graceTitle': 'Waktu {prayer}',
        'graceBody':
            'Anda mahu meluangkan beberapa minit untuk solat sekarang.',
        'snoozeTitle': '{prayer} – peringatan',
        'snoozeBody': 'Tempoh penangguhan telah tamat. Luangkan beberapa minit jika anda mampu.',
        'softTitle': 'Peringatan lembut 🤍',
        'softBody': 'Luangkan beberapa minit untuk {prayer}, jika anda mampu.',
      },
      'fr': <String, String>{
        'prayerTitle': 'Adhan de {prayer}',
        'prayerBody': 'L’heure de la prière de {prayer} est arrivée.',
        'graceTitle': 'L’heure de {prayer}',
        'graceBody': 'Vous souhaitiez consacrer quelques minutes à votre prière maintenant.',
        'snoozeTitle': '{prayer} – rappel',
        'snoozeBody': 'Le délai de report est terminé. Prenez quelques minutes si vous le pouvez.',
        'softTitle': 'Un petit rappel 🤍',
        'softBody': 'Prenez quelques minutes pour {prayer}, si vous le pouvez.',
      },
      'es': <String, String>{
        'prayerTitle': 'Azán de {prayer}',
        'prayerBody': 'Ha comenzado el tiempo de la oración de {prayer}.',
        'graceTitle': 'Hora de {prayer}',
        'graceBody': 'Querías dedicar unos minutos a tu oración ahora.',
        'snoozeTitle': '{prayer} – recordatorio',
        'snoozeBody':
            'El aplazamiento ha terminado. Dedica unos minutos si puedes.',
        'softTitle': 'Un pequeño recordatorio 🤍',
        'softBody': 'Dedica unos minutos a {prayer}, si puedes.',
      },
      'tr': <String, String>{
        'prayerTitle': '{prayer} Ezanı',
        'prayerBody': '{prayer} namazının vakti girdi.',
        'graceTitle': '{prayer} vakti',
        'graceBody': 'Şimdi namazın için birkaç dakika ayırmak istemiştin.',
        'snoozeTitle': '{prayer} – hatırlatma',
        'snoozeBody': 'Erteleme süresi bitti. Müsaitsen birkaç dakika ayır.',
        'softTitle': 'Nazik bir hatırlatma 🤍',
        'softBody': 'Müsaitsen {prayer} için birkaç dakika ayır.',
      },
      'de': <String, String>{
        'prayerTitle': '{prayer} Adhan',
        'prayerBody': 'Die Zeit für das {prayer}-Gebet ist eingetreten.',
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
        'prayerTitle': '{prayer} Adhan',
        'prayerBody': 'The time for {prayer} prayer has begun.',
        'graceTitle': 'Time for {prayer}',
        'graceBody': 'You wanted to make a few minutes for your prayer now.',
        'snoozeTitle': '{prayer} – reminder',
        'snoozeBody': 'Your snooze has ended. Take a few minutes if you can.',
        'softTitle': 'A gentle reminder 🤍',
        'softBody': 'Take a few minutes for {prayer}, if you can.',
      },
      'ar': <String, String>{
        'prayerTitle': 'أذان {prayer}',
        'prayerBody': 'دخل وقت صلاة {prayer}.',
        'graceTitle': 'وقت {prayer}',
        'graceBody': 'أردت أن تخصص الآن بضع دقائق لصلاتك.',
        'snoozeTitle': 'تذكير {prayer}',
        'snoozeBody': 'انتهى وقت التأجيل. خذ بضع دقائق إن استطعت.',
        'softTitle': 'تذكير لطيف 🤍',
        'softBody': 'خذ بضع دقائق من أجل {prayer} إن استطعت.',
      },
      'ur': <String, String>{
        'prayerTitle': '{prayer} کی اذان',
        'prayerBody': '{prayer} کی نماز کا وقت شروع ہو گیا ہے۔',
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
        'prayerTitle': 'د {prayer} اذان',
        'prayerBody': 'د {prayer} د لمانځه وخت پیل شو.',
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
    await _plugin.cancel(id: NotificationIds.oneHourRemaining(prayer));
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
      if (parsed != null &&
          <String>{
            'prayer',
            'reminder',
            'snooze',
            'oneHourRemaining',
          }.contains(parsed.kind)) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  @override
  Future<void> cancelAllFridayPrayerNotifications() async {
    await initialize();
    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();
    for (final PendingNotificationRequest request in pending) {
      final parsed = PrayerNotificationPayload.tryParse(request.payload);
      if (parsed?.kind == 'fridayPrayer') {
        await _plugin.cancel(id: request.id);
      }
    }
    // Fixed IDs also replace/cancel notifications created by older payload
    // versions or already delivered by the operating system.
    await _plugin.cancel(id: 1800000001);
    await _plugin.cancel(id: 1800000002);
  }

  @override
  Future<void> cancelAllRamadanNotifications() async {
    await initialize();
    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();
    for (final PendingNotificationRequest request in pending) {
      if ((request.payload ?? '').startsWith('ramadan|')) {
        await _plugin.cancel(id: request.id);
      }
    }
  }
}
