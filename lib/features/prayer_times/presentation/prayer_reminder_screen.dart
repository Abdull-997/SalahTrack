import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/shared/errors/user_error_message.dart';

class PrayerReminderScreen extends ConsumerStatefulWidget {
  const PrayerReminderScreen({required this.prayerId, super.key});

  final String prayerId;

  @override
  ConsumerState<PrayerReminderScreen> createState() => _PrayerReminderScreenState();
}

class _PrayerReminderScreenState extends ConsumerState<PrayerReminderScreen> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PrayerEntry?> prayer = ref.watch(prayerByIdProvider(widget.prayerId));
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: prayer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => _Message(
          icon: Icons.error_outline_rounded,
          text: userErrorMessage(context, error),
          action: _close,
        ),
        data: (PrayerEntry? entry) {
          if (entry == null) {
            return _Message(
              icon: Icons.notifications_off_outlined,
              text: AppStrings.of(context).t('noData'),
              action: _close,
            );
          }
          return _ReminderContent(
            prayer: entry,
            working: _working,
            onConfirm: () => _confirm(entry),
            onSnooze: entry.status.isFinal ? null : () => _snooze(entry),
            onSkip: entry.status.isFinal ? null : () => _skip(entry),
            onClose: _close,
          );
        },
      ),
    );
  }

  void _close() => context.go('/home');

  Future<void> _confirm(PrayerEntry prayer) => _run(() async {
    await ref.read(prayerCoordinatorProvider).confirm(prayer);
    if (!mounted) return;
    ref.invalidate(todayPrayerDayProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).t('accepted'))),
    );
    _close();
  });

  Future<void> _snooze(PrayerEntry prayer) => _run(() async {
    final PrayerSettings settings = ref.read(settingsControllerProvider).prayerSettings;
    final String language = Localizations.localeOf(context).languageCode;
    await ref.read(prayerCoordinatorProvider).snooze(
      prayer, settings, prayer.type.localizedName(language), language,
    );
    if (!mounted) return;
    ref.invalidate(todayPrayerDayProvider);
    _close();
  });

  Future<void> _skip(PrayerEntry prayer) async {
    final AppStrings s = AppStrings.of(context);
    final bool accepted = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(s.t('skipConfirmTitle')),
            content: Text(s.t('skipConfirmBody')),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.t('noPrayLater'))),
              FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: Text(s.t('yesEnd'))),
            ],
          ),
        ) ?? false;
    if (!accepted) return;
    await _run(() async {
      final PrayerSettings settings = ref.read(settingsControllerProvider).prayerSettings;
      final String language = Localizations.localeOf(context).languageCode;
      await ref.read(prayerCoordinatorProvider).skip(
        prayer, settings, prayer.type.localizedName(language), language,
      );
      if (!mounted) return;
      ref.invalidate(todayPrayerDayProvider);
      _close();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
    } on StateError {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).t('snoozeUnavailable'))),
        );
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userErrorMessage(context, error))));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}

class _ReminderContent extends ConsumerWidget {
  const _ReminderContent({required this.prayer, required this.working, required this.onConfirm, required this.onSnooze, required this.onSkip, required this.onClose});
  final PrayerEntry prayer;
  final bool working;
  final VoidCallback onConfirm;
  final VoidCallback? onSnooze;
  final VoidCallback? onSkip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = AppStrings.of(context);
    final String language = Localizations.localeOf(context).languageCode;
    final bool completed = prayer.status == PrayerStatus.prayed;
    final String confirmation = ref.watch(settingsControllerProvider).prayerSettings.confirmationText.trim();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Icon(completed ? Icons.check_circle_rounded : Icons.notifications_active_rounded, size: 76, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(prayer.type.localizedName(language), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(completed ? s.t('prayed') : s.t('reminderBody'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 30),
            if (!completed) ...<Widget>[
              FilledButton.icon(onPressed: working ? null : onConfirm, icon: const Icon(Icons.check_rounded), label: Text(confirmation.isEmpty ? s.t('confirmPrayer') : confirmation)),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(onPressed: working ? null : onSnooze, icon: const Icon(Icons.snooze_rounded), label: Text(s.t('snoozeIn', params: <String, String>{'minutes': s.number(ref.watch(settingsControllerProvider).prayerSettings.snoozeMinutes)}))),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: working ? null : onSkip, icon: const Icon(Icons.remove_circle_outline_rounded), label: Text(s.t('skipToday'))),
              const SizedBox(height: 10),
            ],
            TextButton(onPressed: working ? null : onClose, child: Text(s.t('home'))),
          ]),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, required this.action});
  final IconData icon;
  final String text;
  final VoidCallback action;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[Icon(icon, size: 56), const SizedBox(height: 16), Text(text, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.tonal(onPressed: action, child: Text(AppStrings.of(context).t('home')))]));
}
