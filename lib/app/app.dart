import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/app/router/app_router.dart';
import 'package:salah_focus/core/notifications/prayer_notification_payload.dart';
import 'package:salah_focus/core/platform/application_locale.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApplicationLocale.followSystem();
      _handleLaunchPayload();
      _syncAutomaticLocationUpdates();
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
      locale: Locale(preferences.localeCode),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
    _recentNotificationEvents.removeWhere((_, receivedAt) =>
        now.difference(receivedAt) >= const Duration(seconds: 2));
    final String event = notification.encode();
    if (_recentNotificationEvents.containsKey(event)) return;
    _recentNotificationEvents[event] = now;
    // A later retry of the same notification must reload a failed destination.
    final Uri route = Uri.parse(notification.routeLocation);
    router.go(route.replace(queryParameters: <String, String>{
      ...route.queryParameters,
      'delivery': '${++_notificationDelivery}',
    }).toString());
  }
}
