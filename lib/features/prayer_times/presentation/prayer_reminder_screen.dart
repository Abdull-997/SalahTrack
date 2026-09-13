import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/notifications/prayer_notification_payload.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/shared/errors/user_error_message.dart';

class PrayerReminderScreen extends ConsumerStatefulWidget {
  const PrayerReminderScreen({
    required this.prayerId,
    this.action = PrayerNotificationAction.open,
    this.eventId,
    this.deliveryId,
    super.key,
  });

  final String prayerId;
  final PrayerNotificationAction action;
  final String? eventId;
  final String? deliveryId;

  @override
  ConsumerState<PrayerReminderScreen> createState() => _PrayerReminderScreenState();
}

class _PrayerReminderScreenState extends ConsumerState<PrayerReminderScreen> {
  static const MethodChannel _alarmChannel = MethodChannel('salah_focus/prayer_alarm');
  PrayerEntry? _prayer;
  Object? _loadError;
  String? _actionError;
  bool _loaded = false;
  bool _working = false;
  bool _confirmed = false;
  bool? _alarmActive;
  int _generation = 0;
  Timer? _snoozeDeadline;

  bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPrayer());
  }

  @override
  void didUpdateWidget(covariant PrayerReminderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayerId != widget.prayerId ||
        oldWidget.action != widget.action || oldWidget.eventId != widget.eventId ||
        oldWidget.deliveryId != widget.deliveryId) {
      unawaited(_loadPrayer());
    }
  }

  @override
  void dispose() {
    _snoozeDeadline?.cancel();
    _setAlarmActive(false);
    super.dispose();
  }

  DateTime get _now => ref.read(clockServiceProvider).nowUtc();

  bool get _alreadySnoozed => _prayer?.status == PrayerStatus.snoozed &&
      (_prayer?.snoozedUntilUtc?.isAfter(_now) ?? false);

  bool get _canSnooze {
    final PrayerEntry? prayer = _prayer;
    if (prayer == null || prayer.status.isFinal || _confirmed) return false;
    final PrayerSettings settings = ref.read(settingsControllerProvider).prayerSettings;
    return (settings.maxSnoozes == null || prayer.snoozeCount < settings.maxSnoozes!) &&
        _now.add(Duration(minutes: settings.snoozeMinutes)).isBefore(prayer.trackingEndsAtUtc);
  }

  // If a snooze limit or expired window removes the alternative, allow a safe
  // exit. A reminder must never force somebody to record a prayer they did not pray.
  bool get _mustChoose => _android && _loaded && _loadError == null &&
      _actionError == null && !_confirmed && !_alreadySnoozed && _canSnooze;

  Future<void> _loadPrayer() async {
    final int generation = ++_generation;
    _snoozeDeadline?.cancel();
    _loaded = false;
    _working = false;
    _confirmed = false;
    _loadError = null;
    _actionError = null;
    _prayer = null;
    try {
      // Read storage on every delivery; the family provider may contain an old
      // pending entry from an earlier visit or before an action was completed.
      final PrayerEntry? entry = await ref.read(prayerCoordinatorProvider).prayerById(widget.prayerId);
      if (!mounted || generation != _generation) return;
      setState(() {
        _prayer = entry;
        _loaded = true;
      });
      _updateAlarmAndDeadline();
      // Let the destination render before showing the action result.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _generation || entry == null) return;
        switch (widget.action) {
          case PrayerNotificationAction.open:
            break;
          case PrayerNotificationAction.markPrayed:
            if (entry.status != PrayerStatus.prayed) unawaited(_confirm());
          case PrayerNotificationAction.snooze:
            unawaited(_snooze());
        }
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loaded = true;
        _loadError = error;
      });
      _setAlarmActive(false);
    }
  }

  void _updateAlarmAndDeadline() {
    _setAlarmActive(_mustChoose);
    _snoozeDeadline?.cancel();
    if (!_canSnooze || _prayer == null) return;
    final int minutes = ref.read(settingsControllerProvider).prayerSettings.snoozeMinutes;
    final Duration remaining = _prayer!.trackingEndsAtUtc
        .subtract(Duration(minutes: minutes)).difference(_now);
    if (remaining <= Duration.zero) return;
    _snoozeDeadline = Timer(remaining, () {
      if (!mounted) return;
      setState(() {});
      _setAlarmActive(_mustChoose);
    });
  }

  void _setAlarmActive(bool active) {
    if (!_android || _alarmActive == active) return;
    _alarmActive = active;
    unawaited(_sendAlarmState(active));
  }

  Future<void> _sendAlarmState(bool active) async {
    try {
      await _alarmChannel.invokeMethod<void>('setAlarmActive', <String, bool>{'active': active});
    } on MissingPluginException {
      // Widget tests and non-native hosts do not have the Android channel.
    } on PlatformException {
      // The actionable notification remains usable if lock-screen flags fail.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsControllerProvider);
    ref.listen(settingsControllerProvider, (_, _) => _updateAlarmAndDeadline());
    return PopScope<void>(
      canPop: !_mustChoose && !_working,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _Message(icon: Icons.error_outline_rounded,
                text: userErrorMessage(context, _loadError!), action: _close)
            : _prayer == null
            ? _Message(icon: Icons.notifications_off_outlined,
                text: AppStrings.of(context).t('noData'), action: _close)
            : _content(context, _prayer!),
      ),
    );
  }

  Widget _content(BuildContext context, PrayerEntry prayer) {
    final AppStrings s = AppStrings.of(context);
    final String language = Localizations.localeOf(context).languageCode;
    final bool completed = _confirmed || prayer.status == PrayerStatus.prayed;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Icon(completed ? Icons.check_circle_rounded : Icons.notifications_active_rounded,
                size: 76, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(prayer.type.localizedName(language), textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (completed) ...<Widget>[
              Text(s.t('alhamdulillah'), textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(s.t('accepted'), textAlign: TextAlign.center),
            ] else
              Text(s.t(_alreadySnoozed ? 'snoozed' : prayer.status.isFinal ? prayer.status.name : 'reminderBody'),
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 30),
            if (!completed) ...<Widget>[
              FilledButton.icon(
                onPressed: _working ? null : _confirm,
                icon: const Icon(Icons.check_rounded), label: Text(s.t('markAsPrayed')),
              ),
              if (!prayer.status.isFinal && !_alreadySnoozed) ...<Widget>[
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: _working || !_canSnooze ? null : _snooze,
                  icon: const Icon(Icons.snooze_rounded),
                  label: Text(s.t('snoozeIn', params: <String, String>{
                    'minutes': s.number(ref.read(settingsControllerProvider).prayerSettings.snoozeMinutes),
                  })),
                ),
                if (!_canSnooze) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(s.t('snoozeUnavailable'), textAlign: TextAlign.center),
                ],
              ],
            ],
            if (_actionError != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(_actionError!, textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_working) ...<Widget>[
              const SizedBox(height: 16), const CircularProgressIndicator(),
            ],
            if (!_mustChoose) ...<Widget>[
              const SizedBox(height: 10),
              TextButton(onPressed: _working ? null : _close, child: Text(s.t('home'))),
            ],
          ]),
        ),
      ),
    );
  }

  void _close() {
    _setAlarmActive(false);
    context.go('/home');
  }

  Future<void> _confirm() => _run(snooze: false);
  Future<void> _snooze() => _run(snooze: true);

  Future<void> _run({required bool snooze}) async {
    if (_working) return;
    final int generation = _generation;
    final String prayerId = widget.prayerId;
    setState(() {
      _working = true;
      _actionError = null;
    });
    try {
      final coordinator = ref.read(prayerCoordinatorProvider);
      final PrayerEntry? current = await coordinator.prayerById(prayerId);
      if (!mounted || generation != _generation) return;
      if (current == null) {
        setState(() => _prayer = null);
        _setAlarmActive(false);
        return;
      }
      final PrayerEntry updated;
      if (snooze) {
        final PrayerSettings settings = ref.read(settingsControllerProvider).prayerSettings;
        final String language = Localizations.localeOf(context).languageCode;
        updated = await coordinator.snooze(current, settings,
            current.type.localizedName(language), language);
      } else {
        updated = current.status == PrayerStatus.prayed
            ? current : await coordinator.confirm(current);
      }
      if (!mounted || generation != _generation) return;
      ref.invalidate(prayerByIdProvider(prayerId));
      ref.invalidate(todayPrayerDayProvider);
      setState(() {
        _prayer = updated;
        _confirmed = !snooze;
      });
      _setAlarmActive(false);
      if (snooze) _close();
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _actionError = snooze && error is StateError
          ? AppStrings.of(context).t('snoozeUnavailable')
          : userErrorMessage(context, error));
      _setAlarmActive(false);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _working = false);
        _updateAlarmAndDeadline();
      }
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, required this.action});
  final IconData icon;
  final String text;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Icon(icon, size: 56), const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center), const SizedBox(height: 16),
        FilledButton.tonal(onPressed: action, child: Text(AppStrings.of(context).t('home'))),
      ]),
    ),
  );
}
