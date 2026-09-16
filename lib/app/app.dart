import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_language.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/app/router/app_router.dart';
import 'package:salah_focus/core/notifications/prayer_notification_payload.dart';
import 'package:salah_focus/core/platform/application_locale.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';

class SalahFocusApp extends ConsumerStatefulWidget {
  const SalahFocusApp({super.key});

  @override
  ConsumerState<SalahFocusApp> createState() => _SalahFocusAppState();
}

class _SalahFocusAppState extends ConsumerState<SalahFocusApp> {
  StreamSubscription<UserLocation>? _automaticLocationSubscription;
  final Map<String, DateTime> _recentNotificationEvents = <String, DateTime>{};
  int _notificationDelivery = 0;
  bool _receivedLivePayload = false;
  String? _lastRamadanScheduleKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApplicationLocale.followSystem();
      _handleLaunchPayload();
      _syncAutomaticLocationUpdates();
      _syncFridayPrayerReminders();
      _syncRamadanReminders();
    });
  }

  @override
  void dispose() {
    _automaticLocationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(settingsControllerProvider);
    final GoRouter router = ref.watch(goRouterProvider);
    ref.listen<AsyncValue<String>>(notificationPayloadProvider, (
      _,
      AsyncValue<String> next,
    ) {
      next.whenData((String payload) {
        if (PrayerNotificationPayload.tryParse(payload) == null) return;
        _receivedLivePayload = true;
        _routePayload(router, payload);
      });
    });
    ref.listen(
      settingsControllerProvider,
      (_, _) => _syncAutomaticLocationUpdates(),
    );
    ref.listen(
      settingsControllerProvider.select(
        (preferences) => (
          fridayPrayer: preferences.prayerSettings.fridayPrayer,
          timezoneId:
              preferences.location?.timezoneId ??
              ref.read(deviceTimezoneIdProvider),
          localeCode: preferences.localeCode,
        ),
      ),
      (_, _) => _syncFridayPrayerReminders(),
    );
    ref.listen(
      settingsControllerProvider.select(
        (preferences) => (
          ramadan: preferences.ramadanSettings,
          localeCode: preferences.localeCode,
        ),
      ),
      (_, _) => _syncRamadanReminders(),
    );
    ref.listen<AsyncValue<PrayerDay?>>(todayPrayerDayProvider, (_, next) {
      if (next.hasValue) _syncRamadanReminders();
    });

    final ThemeMode themeMode = switch (preferences.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppStrings.of(context).t('appName'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: appLocaleFor(preferences.localeCode),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        AppStrings.cupertinoFallbackDelegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (BuildContext context, Widget? child) => Directionality(
        textDirection: textDirectionForLanguage(preferences.localeCode),
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: router,
    );
  }

  Future<void> _syncAutomaticLocationUpdates() async {
    await _automaticLocationSubscription?.cancel();
    _automaticLocationSubscription = null;
    final preferences = ref.read(settingsControllerProvider);
    final UserLocation? location = preferences.location;
    if (location == null || !location.isAutomatic) return;
    _automaticLocationSubscription = ref
        .read(locationServiceProvider)
        .automaticLocationUpdates(
          deviceTimezoneId: ref.read(deviceTimezoneIdProvider),
          languageCode: preferences.localeCode,
        )
        .listen((UserLocation updated) async {
          final UserLocation? current = ref
              .read(settingsControllerProvider)
              .location;
          if (current == null ||
              !current.isAutomatic ||
              (current.latitude - updated.latitude).abs() > 0.005 ||
              (current.longitude - updated.longitude).abs() > 0.005) {
            await ref
                .read(settingsControllerProvider.notifier)
                .setLocation(updated);
            ref.invalidate(todayPrayerDayProvider);
          }
        });
  }

  Future<void> _syncFridayPrayerReminders() async {
    final preferences = ref.read(settingsControllerProvider);
    try {
      await ref
          .read(fridayPrayerReminderPlannerProvider)
          .reschedule(
            preferences.prayerSettings.fridayPrayer,
            timezoneId:
                preferences.location?.timezoneId ??
                ref.read(deviceTimezoneIdProvider),
            languageCode: preferences.localeCode,
            nowUtc: ref.read(clockServiceProvider).nowUtc(),
          );
    } on Object {
      // Reminder scheduling must never prevent the main interface from loading.
    }
  }

  Future<void> _syncRamadanReminders() async {
    final preferences = ref.read(settingsControllerProvider);
    PrayerDay? today;
    if (preferences.ramadanSettings.enabled && preferences.location != null) {
      try {
        today = await ref.read(todayPrayerDayProvider.future);
      } on Object {
        today = null;
      }
    }
    try {
      final String scheduleKey = <Object?>[
        preferences.ramadanSettings.hashCode,
        preferences.localeCode,
        today?.localDate,
        today?.hijriDay,
        today?.hijriMonth,
        for (final PrayerEntry entry in today?.entries ?? const <PrayerEntry>[])
          entry.scheduledAtUtc.microsecondsSinceEpoch,
      ].join('|');
      if (_lastRamadanScheduleKey == scheduleKey) return;
      await ref
          .read(ramadanReminderCoordinatorProvider)
          .reschedule(
            today,
            preferences.ramadanSettings,
            nowUtc: ref.read(clockServiceProvider).nowUtc(),
            languageCode: preferences.localeCode,
          );
      _lastRamadanScheduleKey = scheduleKey;
    } on Object {
      // Ramadan reminders must never prevent the app from loading or alter
      // the independent prayer notification schedule.
    }
  }

  Future<void> _handleLaunchPayload() async {
    final service = ref.read(notificationServiceProvider);
    final String? payload = await service.takeInitialPayload();
    // A foreground response is newer than the launch intent. Do not let a
    // delayed plugin launch read replace the screen selected by that response.
    if (!mounted || payload == null || _receivedLivePayload) return;
    _routePayload(ref.read(goRouterProvider), payload);
  }

  void _routePayload(GoRouter router, String payload) {
    final PrayerNotificationPayload? notification =
        PrayerNotificationPayload.tryParse(payload);
    if (notification == null) return;
    final DateTime now = DateTime.now();
    _recentNotificationEvents.removeWhere(
      (_, receivedAt) =>
          now.difference(receivedAt) >= const Duration(seconds: 2),
    );
    final String event = notification.encode();
    if (_recentNotificationEvents.containsKey(event)) return;
    _recentNotificationEvents[event] = now;
    // A later retry of the same notification must reload a failed destination.
    final Uri route = Uri.parse(notification.routeLocation);
    router.go(
      route
          .replace(
            queryParameters: <String, String>{
              ...route.queryParameters,
              'delivery': '${++_notificationDelivery}',
            },
          )
          .toString(),
    );
  }
}
