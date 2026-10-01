import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/time/timezone_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/statistics/domain/prayer_statistics.dart';
import 'package:salah_focus/shared/errors/user_error_message.dart';

final statisticsHistoryProvider = FutureProvider.autoDispose<List<PrayerEntry>>(
  (Ref ref) => ref
      .watch(appDatabaseProvider)
      .prayerEntriesBetween('0000-01-01', '9999-12-31'),
);

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  StatisticsRange _range = StatisticsRange.last30Days;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final history = ref.watch(statisticsHistoryProvider);
    final prefs = ref.watch(settingsControllerProvider);
    final DateTime nowUtc = ref.watch(clockServiceProvider).nowUtc();
    final DateTime localToday = TimezoneService.toLocal(
      nowUtc,
      prefs.location?.timezoneId ?? 'UTC',
    );
    return Scaffold(
      appBar: AppBar(title: Text(s.t('statistics'))),
      body: history.when(
        data: (List<PrayerEntry> entries) {
          final PrayerStatistics stats = PrayerStatistics.calculate(
            entries,
            nowUtc: nowUtc,
            localToday: localToday,
            range: _range,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: <Widget>[
              DropdownButtonFormField<StatisticsRange>(
                key: const ValueKey<String>('statistics-range'),
                initialValue: _range,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: <DropdownMenuItem<StatisticsRange>>[
                  for (final StatisticsRange range in StatisticsRange.values)
                    DropdownMenuItem(
                      value: range,
                      child: Text(s.t(_rangeKey(range))),
                    ),
                ],
                onChanged: (StatisticsRange? value) {
                  if (value != null) setState(() => _range = value);
                },
              ),
              const SizedBox(height: 16),
              if (stats.totalRecorded == 0)
                _MessageCard(text: s.t('noPrayerHistoryYet'))
              else ...<Widget>[
                _OverallCard(stats: stats),
                const SizedBox(height: 16),
                Text(
                  s.t('prayersByType'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final PrayerType type in PrayerType.values) ...<Widget>[
                  _PrayerCard(type: type, count: stats.byPrayer[type]!),
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 8),
              _DelayCard(stats: stats),
              const SizedBox(height: 16),
              _ReasonsCard(stats: stats),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  userErrorMessage(context, error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(statisticsHistoryProvider),
                  child: Text(s.t('retry')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _rangeKey(StatisticsRange range) => switch (range) {
  StatisticsRange.last7Days => 'last7Days',
  StatisticsRange.last30Days => 'last30Days',
  StatisticsRange.thisMonth => 'thisMonth',
  StatisticsRange.allTime => 'allTime',
};

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(20), child: Text(text)),
  );
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.stats});
  final PrayerStatistics stats;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.t('overallCompletion'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${s.number((stats.completion * 100).round())}%',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: stats.completion),
            const SizedBox(height: 12),
            _Metric(label: s.t('prayed'), value: s.number(stats.totalPrayed)),
            _Metric(
              label: s.t('missed'),
              value: s.number(stats.totalNotConfirmed),
            ),
            _Metric(
              label: s.t('completeDays'),
              value: s.number(stats.completeDays),
            ),
            _Metric(
              label: s.t('currentStreak'),
              value: s.number(stats.currentStreak),
            ),
            _Metric(
              label: s.t('bestStreak'),
              value: s.number(stats.bestStreak),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({required this.type, required this.count});
  final PrayerType type;
  final PrayerCount count;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return Card(
      key: ValueKey<String>('statistics-${type.name}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    type.localizedName(s.locale.languageCode),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${s.number(count.prayed)}/${s.number(count.total)} · '
                  '${s.number((count.completion * 100).round())}%',
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: count.completion),
            const SizedBox(height: 6),
            Text(
              '${s.t('prayed')}: ${s.number(count.prayed)}  ·  '
              '${s.t('missed')}: ${s.number(count.notConfirmed)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DelayCard extends StatelessWidget {
  const _DelayCard({required this.stats});
  final PrayerStatistics stats;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final PrayerType? most = stats.mostSnoozedPrayer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.t('delayedPrayers'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (stats.totalSnoozes == 0)
              Text(s.t('noDelayedPrayers'))
            else ...<Widget>[
              _Metric(
                label: s.t('snoozeActions'),
                value: s.number(stats.totalSnoozes),
              ),
              if (most != null)
                _Metric(
                  label: s.t('mostDelayedPrayer'),
                  value:
                      '${most.localizedName(s.locale.languageCode)} · '
                      '${s.number(stats.snoozesByPrayer[most] ?? 0)}',
                ),
            ],
            _Metric(
              label: s.t('stoppedReminders'),
              value: s.number(stats.stoppedReminders),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonsCard extends StatelessWidget {
  const _ReasonsCard({required this.stats});
  final PrayerStatistics stats;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final entries = stats.reasonCounts.entries.toList()
      ..sort((a, b) {
        final int count = b.value.compareTo(a.value);
        return count != 0 ? count : a.key.compareTo(b.key);
      });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.t('reasons'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              Text(s.t('noReasonsRecorded'))
            else ...<Widget>[
              Text(
                s.t('reasonScopeHelp'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _reasonLabel(s, entry.key),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${s.number(entry.value)} · '
                        '${s.number((entry.value / stats.totalReasonActions * 100).round())}%',
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _reasonLabel(AppStrings s, String raw) {
  if (raw.isEmpty) return s.t('noReasonProvided');
  if (raw.startsWith('preset:')) {
    final String key = raw.substring('preset:'.length);
    const keys = <String>{
      'reasonAlreadyPrayed',
      'reasonCannotNow',
      'reasonOutside',
      'reasonSick',
      'reasonOther',
    };
    if (keys.contains(key)) return s.t(key);
  }
  return raw;
}
