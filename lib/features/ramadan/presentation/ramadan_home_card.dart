import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/time/timezone_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/ramadan/application/ramadan_providers.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_record.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';

class RamadanHomeCard extends ConsumerWidget {
  const RamadanHomeCard({required this.nowUtc, super.key});

  final DateTime nowUtc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<RamadanTodayData?> value = ref.watch(ramadanTodayProvider);
    return value.when(
      data: (RamadanTodayData? data) => data == null
          ? const SizedBox.shrink()
          : _RamadanCardContent(data: data, nowUtc: nowUtc),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _RamadanCardContent extends ConsumerWidget {
  const _RamadanCardContent({required this.data, required this.nowUtc});

  final RamadanTodayData data;
  final DateTime nowUtc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = AppStrings.of(context);
    final settings = ref.watch(settingsControllerProvider).ramadanSettings;
    final fajr = data.prayerDay.entries.firstWhere(
      (entry) => entry.type == PrayerType.fajr,
    );
    final maghrib = data.prayerDay.entries.firstWhere(
      (entry) => entry.type == PrayerType.maghrib,
    );
    final DateTime localFajr = TimezoneService.toLocal(
      fajr.scheduledAtUtc,
      fajr.timezoneId,
    );
    final DateTime localMaghrib = TimezoneService.toLocal(
      maghrib.scheduledAtUtc,
      maghrib.timezoneId,
    );
    final bool night =
        nowUtc.isBefore(fajr.scheduledAtUtc) ||
        !nowUtc.isBefore(maghrib.scheduledAtUtc);
    final int prayed = data.prayerDay.entries
        .where((entry) => entry.status == PrayerStatus.prayed)
        .length;
    final int completedGoals = data.goals
        .where((goal) => data.completedGoalIds.contains(goal.id))
        .length;

    String countdown;
    if (nowUtc.isBefore(fajr.scheduledAtUtc)) {
      countdown = s.t(
        'untilSuhurEnds',
        params: <String, String>{
          'duration': _duration(s, fajr.scheduledAtUtc.difference(nowUtc)),
        },
      );
    } else if (nowUtc.isBefore(maghrib.scheduledAtUtc)) {
      countdown = s.t(
        'untilIftar',
        params: <String, String>{
          'duration': _duration(s, maghrib.scheduledAtUtc.difference(nowUtc)),
        },
      );
    } else {
      countdown = s.t('iftarHasBegun');
    }

    return Card(
      key: const ValueKey<String>('ramadan-home-card'),
      color: Theme.of(context).colorScheme.primaryContainer.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.32 : 0.55,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.nights_stay_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.t(
                      'ramadanDay',
                      params: <String, String>{
                        'day': s.number(data.ramadanDate.day),
                      },
                    ),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _TimeBlock(
                    icon: Icons.free_breakfast_outlined,
                    label: s.t('suhur'),
                    value: s.t(
                      'suhurEndsAt',
                      params: <String, String>{'time': s.time(localFajr)},
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeBlock(
                    icon: Icons.wb_twilight_outlined,
                    label: s.t('iftar'),
                    value: s.t(
                      'iftarAt',
                      params: <String, String>{'time': s.time(localMaghrib)},
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                const Icon(Icons.timer_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    countdown,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              s.t('fastToday'),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final FastingStatus status in FastingStatus.values)
                  ChoiceChip(
                    key: ValueKey<String>('fasting-${status.name}'),
                    label: Text(_fastingLabel(s, status)),
                    avatar: Icon(_fastingIcon(status), size: 18),
                    selected: data.record.fastingStatus == status,
                    onSelected: (_) => _setFasting(ref, status),
                  ),
              ],
            ),
            if (night && settings.tarawihTrackingEnabled) ...<Widget>[
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const ValueKey<String>('home-tarawih-completed'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(s.t('tarawih')),
                subtitle: Text(
                  data.record.tarawihCompleted == true
                      ? s.t('completed')
                      : s.t('notRecorded'),
                ),
                value: data.record.tarawihCompleted == true,
                onChanged: (bool? value) =>
                    _setTarawih(ref, value == true ? true : null),
              ),
            ],
            if (night && settings.qiyamTrackingEnabled)
              CheckboxListTile(
                key: const ValueKey<String>('home-qiyam-completed'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(s.t('qiyam')),
                subtitle: Text(
                  data.record.qiyamCompleted == true
                      ? s.t('completed')
                      : s.t('notRecorded'),
                ),
                value: data.record.qiyamCompleted == true,
                onChanged: (bool? value) =>
                    _setQiyam(ref, value == true ? true : null),
              ),
            const Divider(height: 28),
            Text(
              s.t('ramadanDailySummary'),
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _SummaryChip(
                  icon: _fastingIcon(data.record.fastingStatus),
                  label:
                      '${s.t('fasting')}: ${_fastingLabel(s, data.record.fastingStatus)}',
                ),
                _SummaryChip(
                  icon: Icons.checklist_rounded,
                  label:
                      '${s.t('dailyPrayers')}: ${s.number(prayed)}/${s.number(5)}',
                ),
                if (settings.tarawihTrackingEnabled)
                  _SummaryChip(
                    icon: Icons.mosque_outlined,
                    label:
                        '${s.t('tarawih')}: ${_optionalLabel(s, data.record.tarawihCompleted)}',
                  ),
                if (settings.qiyamTrackingEnabled)
                  _SummaryChip(
                    icon: Icons.bedtime_outlined,
                    label:
                        '${s.t('qiyam')}: ${_optionalLabel(s, data.record.qiyamCompleted)}',
                  ),
                _SummaryChip(
                  icon: Icons.flag_outlined,
                  label:
                      '${s.t('ramadanGoals')}: ${s.number(completedGoals)}/${s.number(data.goals.length)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setFasting(WidgetRef ref, FastingStatus status) async {
    await ref.read(ramadanControllerProvider).setFasting(data.record, status);
    _refresh(ref);
  }

  Future<void> _setTarawih(WidgetRef ref, bool? completed) async {
    await ref
        .read(ramadanControllerProvider)
        .setTarawih(data.record, completed);
    _refresh(ref);
  }

  Future<void> _setQiyam(WidgetRef ref, bool? completed) async {
    await ref.read(ramadanControllerProvider).setQiyam(data.record, completed);
    _refresh(ref);
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 21),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, maxLines: 1)),
        ],
      ),
    ),
  );
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    labelStyle: Theme.of(context).textTheme.bodySmall,
  );
}

String _fastingLabel(AppStrings s, FastingStatus status) => switch (status) {
  FastingStatus.fasted => s.t('fasted'),
  FastingStatus.didNotFast => s.t('didNotFast'),
  FastingStatus.notRecorded => s.t('notRecorded'),
};

IconData _fastingIcon(FastingStatus status) => switch (status) {
  FastingStatus.fasted => Icons.check_rounded,
  FastingStatus.didNotFast => Icons.horizontal_rule_rounded,
  FastingStatus.notRecorded => Icons.circle_outlined,
};

String _optionalLabel(AppStrings s, bool? completed) =>
    completed == true ? s.t('completed') : s.t('notRecorded');

String _duration(AppStrings s, Duration duration) {
  final int totalMinutes = duration.inSeconds <= 0
      ? 0
      : (duration.inSeconds + 59) ~/ 60;
  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;
  if (hours == 0) return s.minutes(minutes);
  final String zero = s.number(0);
  return '${s.number(hours)}:${s.number(minutes).padLeft(2, zero)}';
}

void _refresh(WidgetRef ref) {
  ref.invalidate(ramadanTodayProvider);
  ref.invalidate(ramadanTrackerDataProvider);
}
