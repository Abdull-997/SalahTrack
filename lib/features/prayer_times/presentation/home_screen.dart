import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/time/timezone_service.dart';
import 'package:salah_focus/core/review/review_request_policy.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/friday_prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_calendar.dart';
import 'package:salah_focus/features/ramadan/presentation/ramadan_home_card.dart';
import 'package:salah_focus/shared/errors/user_error_message.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _timer;
  Timer? _reviewTimer;
  late DateTime _nowUtc;
  late int _lastMinute;
  bool _isVisible = false;
  bool _hasVisitedHome = false;
  String? _loadedLocationKey;

  @override
  void initState() {
    super.initState();
    _nowUtc = ref.read(clockServiceProvider).nowUtc();
    _lastMinute = _nowUtc.millisecondsSinceEpoch ~/ 60000;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    // Kept-alive tabs must not repaint or refresh data while offstage.
    if (!TickerMode.valuesOf(context).enabled) {
      _isVisible = false;
      _reviewTimer?.cancel();
      return;
    }
    if (!_isVisible) {
      _isVisible = true;
      if (_hasVisitedHome) {
        _reviewTimer?.cancel();
        _reviewTimer = Timer(const Duration(seconds: 4), _maybeRequestReview);
      } else {
        _hasVisitedHome = true;
      }
    }
    _nowUtc = ref.read(clockServiceProvider).nowUtc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && TickerMode.valuesOf(context).enabled) _tick();
    });
  }

  void _tick() {
    if (!mounted) return;
    final DateTime now = ref.read(clockServiceProvider).nowUtc();
    setState(() => _nowUtc = now);
    final int minute = now.millisecondsSinceEpoch ~/ 60000;
    if (_lastMinute != minute) {
      _lastMinute = minute;
      ref.invalidate(todayPrayerDayProvider);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reviewTimer?.cancel();
    super.dispose();
  }

  Future<void> _maybeRequestReview() async {
    if (!mounted || !TickerMode.valuesOf(context).enabled) return;
    final preferences = ref.read(settingsControllerProvider);
    final DateTime nowUtc = ref.read(clockServiceProvider).nowUtc();
    if (!ReviewRequestPolicy.isEligible(preferences, nowUtc)) return;

    final PrayerDay? day = ref.read(todayPrayerDayProvider).value;
    if (day == null ||
        day.entries.any(
          (PrayerEntry entry) =>
              entry.status == PrayerStatus.active ||
              entry.status == PrayerStatus.pending ||
              entry.status == PrayerStatus.snoozed,
        )) {
      return;
    }

    // Persist before invoking the platform API: the OS is allowed to suppress
    // the dialog, and this automatic request must still happen at most once.
    await ref
        .read(settingsControllerProvider.notifier)
        .markReviewRequestAttempted();
    try {
      final service = ref.read(appReviewServiceProvider);
      if (await service.isAvailable()) await service.requestReview();
    } on Object {
      // A store service failure must not disturb Home or cause repeated asks.
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final preferences = ref.watch(settingsControllerProvider);
    final AsyncValue<PrayerDay?> dayAsync = ref.watch(todayPrayerDayProvider);
    final location = preferences.location;
    final String? locationKey = location == null
        ? null
        : '${location.latitude}|${location.longitude}|${location.timezoneId}';
    final bool locationChanged = _loadedLocationKey != locationKey;
    if (!dayAsync.isLoading && dayAsync.hasValue) {
      _loadedLocationKey = locationKey;
    }
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todayPrayerDayProvider);
        await ref.read(todayPrayerDayProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.nightlight_round,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          s.t('appName'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (preferences.location != null)
                          Text(
                            preferences.location!.label.isEmpty
                                ? s.t('currentLocation')
                                : preferences.location!.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          dayAsync.when(
            // Preserve content on ordinary refreshes, but hide the previous
            // city's times while a newly selected location is loading.
            skipLoadingOnReload: !locationChanged,
            skipLoadingOnRefresh: !locationChanged,
            data: (PrayerDay? day) {
              if (day == null) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoDataState(
                    hasLocation: preferences.location != null,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                sliver: SliverList.list(
                  children: <Widget>[
                    if (day.hijriDate != null) ...<Widget>[
                      Text(
                        s.hijriDate(
                          day.hijriDate!,
                          day: day.hijriDay,
                          month: day.hijriMonth,
                          year: day.hijriYear,
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      s.fullDate(
                        TimezoneService.toLocal(_nowUtc, day.timezoneId),
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    _NextPrayerCard(day: day, nowUtc: _nowUtc),
                    const SizedBox(height: 14),
                    if (preferences.ramadanSettings.enabled &&
                        RamadanCalendar.isRamadan(day)) ...<Widget>[
                      RamadanHomeCard(nowUtc: _nowUtc),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      s.t('today'),
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    if (_isFriday(day.localDate) &&
                        preferences.prayerSettings.fridayPrayer.enabled)
                      for (final PrayerEntry prayer in day.entries) ...<Widget>[
                        _PrayerTile(prayer: prayer),
                        const SizedBox(height: 10),
                        if (prayer.type == PrayerType.dhuhr) ...<Widget>[
                          _FridayPrayerTile(
                            settings: preferences.prayerSettings.fridayPrayer,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ]
                    else
                      for (final PrayerEntry prayer in day.entries) ...<Widget>[
                        _PrayerTile(prayer: prayer),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              );
            },
            error: (Object error, StackTrace stackTrace) => SliverFillRemaining(
              hasScrollBody: false,
              child: _ErrorState(error: error),
            ),
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isFriday(String localDate) {
  final DateTime? date = DateTime.tryParse(localDate);
  return date?.weekday == DateTime.friday;
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({required this.day, required this.nowUtc});

  final PrayerDay day;
  final DateTime nowUtc;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    PrayerEntry? next;
    for (final PrayerEntry prayer in day.entries) {
      if (!prayer.status.isFinal && nowUtc.isBefore(prayer.trackingEndsAtUtc)) {
        next = prayer;
        break;
      }
    }
    if (next == null && day.entries.isNotEmpty) {
      next = day.entries.last;
    }
    if (next == null) return const SizedBox.shrink();
    final DateTime local = TimezoneService.toLocal(
      next.scheduledAtUtc,
      next.timezoneId,
    );
    final String time = s.time(local);
    final Duration remaining = next.scheduledAtUtc.difference(nowUtc);
    final bool waiting = remaining.isNegative;
    final String countdown = waiting
        ? _statusLabel(context, next.status)
        : _duration(context, remaining);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.t('nextPrayer'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Text(
                    next.type.localizedName(
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  waiting
                      ? Icons.notifications_active_outlined
                      : Icons.timer_outlined,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  countdown,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _duration(BuildContext context, Duration value) {
    final int seconds = value.inSeconds < 0
        ? 0
        : (value.inSeconds > 86400 ? 86400 : value.inSeconds);
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int secs = seconds % 60;
    final AppStrings s = AppStrings.of(context);
    final String zero = s.number(0);
    return '${s.number(hours).padLeft(2, zero)}:'
        '${s.number(minutes).padLeft(2, zero)}:'
        '${s.number(secs).padLeft(2, zero)}';
  }
}

class _PrayerTile extends ConsumerStatefulWidget {
  const _PrayerTile({required this.prayer});

  final PrayerEntry prayer;

  @override
  ConsumerState<_PrayerTile> createState() => _PrayerTileState();
}

class _PrayerTileState extends ConsumerState<_PrayerTile> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final PrayerEntry prayer = widget.prayer;
    final String language = Localizations.localeOf(context).languageCode;
    final DateTime local = TimezoneService.toLocal(
      prayer.scheduledAtUtc,
      prayer.timezoneId,
    );
    final String time = AppStrings.of(context).time(local);
    final bool actionable =
        prayer.status == PrayerStatus.active ||
        prayer.status == PrayerStatus.pending ||
        prayer.status == PrayerStatus.snoozed;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: actionable && !_working
            ? () => context.push('/reminder/${Uri.encodeComponent(prayer.id)}')
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: <Widget>[
              _StatusIcon(status: prayer.status),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      prayer.type.localizedName(language),
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _statusLabel(context, prayer.status),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (actionable) ...<Widget>[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: AppStrings.of(context).t('prayed'),
                  onPressed: _working ? null : () => _confirm(prayer),
                  icon: _working
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(PrayerEntry prayer) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await ref.read(prayerCoordinatorProvider).confirm(prayer);
      ref.invalidate(todayPrayerDayProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).t('accepted'))),
      );
    } catch (error) {
      // The database may already contain the update if only notification
      // cancellation failed, so always reload before showing the error.
      ref.invalidate(todayPrayerDayProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userErrorMessage(context, error))));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}

class _FridayPrayerTile extends StatelessWidget {
  const _FridayPrayerTile({required this.settings});

  final FridayPrayerSettings settings;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final Color primary = Theme.of(context).colorScheme.primary;
    final String time = s.time(
      DateTime(2000, 1, 1, settings.hour, settings.minute),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mosque_outlined, color: primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s.t('fridayPrayer'),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s.t('fridayPrayerReminderOnly'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final PrayerStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final (IconData, Color) appearance = switch (status) {
      PrayerStatus.prayed => (Icons.check_rounded, scheme.primary),
      PrayerStatus.active => (
        Icons.notifications_active_outlined,
        scheme.tertiary,
      ),
      PrayerStatus.pending => (
        Icons.notifications_active_outlined,
        scheme.error,
      ),
      PrayerStatus.snoozed => (Icons.snooze_rounded, scheme.secondary),
      PrayerStatus.skipped => (Icons.remove_rounded, scheme.outline),
      PrayerStatus.missed => (Icons.circle_outlined, scheme.outline),
      PrayerStatus.upcoming => (Icons.schedule_rounded, scheme.outline),
    };
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: appearance.$2.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(appearance.$1, color: appearance.$2, size: 22),
    );
  }
}

String _statusLabel(BuildContext context, PrayerStatus status) {
  final AppStrings s = AppStrings.of(context);
  return switch (status) {
    PrayerStatus.prayed => s.t('prayed'),
    PrayerStatus.snoozed => s.t('snoozed'),
    PrayerStatus.skipped => s.t('skipped'),
    PrayerStatus.missed => s.t('missed'),
    PrayerStatus.upcoming => s.t('upcoming'),
    PrayerStatus.active => s.t('active'),
    PrayerStatus.pending => s.t('pending'),
  };
}

class _NoDataState extends StatelessWidget {
  const _NoDataState({required this.hasLocation});

  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            hasLocation
                ? Icons.cloud_off_outlined
                : Icons.location_off_outlined,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            hasLocation ? s.t('noData') : s.t('needLocation'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          FilledButton.tonal(
            onPressed: () => context.go('/settings'),
            child: Text(s.t('settings')),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.wifi_off_rounded, size: 56),
          const SizedBox(height: 16),
          Text(userErrorMessage(context, error), textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.tonal(
            onPressed: () => ref.invalidate(todayPrayerDayProvider),
            child: Text(s.t('retry')),
          ),
        ],
      ),
    );
  }
}
