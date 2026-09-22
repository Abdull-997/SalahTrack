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

class SalahTrackApp extends ConsumerStatefulWidget {
  const SalahTrackApp({super.key});

  @override
  ConsumerState<SalahTrackApp> createState() => _SalahTrackAppState();
}

class _SalahTrackAppState extends ConsumerState<SalahTrackApp> {
  StreamSubscription<UserLocation>? _automaticLocationSubscription;
  Future<void> _pendingAutomaticLocationUpdate = Future<void>.value();
  int _automaticLocationGeneration = 0;
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
      settingsControllerProvider.select(
        (preferences) => (
          location: preferences.location,
          localeCode: preferences.localeCode,
        ),
      ),
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
      if (next.hasValue) {
        _syncFridayPrayerReminders();
        _syncRamadanReminders();
      }
    });

    final ThemeMode themeMode = switch (preferences.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppStrings.of(context).t('appName'),
      theme: AppTheme.light(languageCode: preferences.localeCode),
      darkTheme: AppTheme.dark(languageCode: preferences.localeCode),
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
    final int generation = ++_automaticLocationGeneration;
    final StreamSubscription<UserLocation>? previous =
        _automaticLocationSubscription;
    _automaticLocationSubscription = null;
    await previous?.cancel();
    if (!mounted || generation != _automaticLocationGeneration) return;
    final preferences = ref.read(settingsControllerProvider);
    final UserLocation? location = preferences.location;
    if (location == null || !location.isAutomatic) return;
    final StreamSubscription<UserLocation> subscription = ref
        .read(locationServiceProvider)
        .automaticLocationUpdates(
          deviceTimezoneId: ref.read(deviceTimezoneIdProvider),
          languageCode: preferences.localeCode,
        )
        .listen(
          (UserLocation updated) {
            final Future<void> update = _pendingAutomaticLocationUpdate.then(
              (_) => _saveAutomaticLocation(updated, generation),
            );
            _pendingAutomaticLocationUpdate = update.then<void>(
              (_) {},
              onError: (Object _, StackTrace _) {},
            );
          },
          // Permission or service changes can terminate a native location
          // stream. Treat that as a recoverable state; the user can re-enable
          // automatic location from Settings without an uncaught zone error.
          onError: (Object _, StackTrace _) {},
          cancelOnError: true,
        );
    if (!mounted || generation != _automaticLocationGeneration) {
      await subscription.cancel();
      return;
    }
    _automaticLocationSubscription = subscription;
  }

  Future<void> _saveAutomaticLocation(
    UserLocation updated,
    int generation,
  ) async {
    if (!mounted || generation != _automaticLocationGeneration) return;
    final UserLocation? current = ref.read(settingsControllerProvider).location;
    if (current == null || !current.isAutomatic) return;
    if ((current.latitude - updated.latitude).abs() <= 0.005 &&
        (current.longitude - updated.longitude).abs() <= 0.005) {
      return;
    }
    try {
      await ref.read(settingsControllerProvider.notifier).setLocation(updated);
      if (!mounted || generation != _automaticLocationGeneration) return;
      ref.invalidate(todayPrayerDayProvider);
    } on Object {
      // A transient preferences failure must not escape a stream callback.
    }
  }

  Future<void> _syncFridayPrayerReminders() async {
    final preferences = ref.read(settingsControllerProvider);
    List<PrayerEntry> fridayDhuhrs = const <PrayerEntry>[];
    try {
      final UserLocation? location = preferences.location;
      if (preferences.prayerSettings.fridayPrayer.enabled && location != null) {
        fridayDhuhrs = await ref
            .read(prayerCoordinatorProvider)
            .upcomingFridayDhuhrs(
              location: location,
              settings: preferences.prayerSettings,
              nowUtc: ref.read(clockServiceProvider).nowUtc(),
            );
      }
      await ref
          .read(fridayPrayerReminderPlannerProvider)
          .reschedule(
            preferences.prayerSettings.fridayPrayer,
            fridayDhuhrEntries: fridayDhuhrs,
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
