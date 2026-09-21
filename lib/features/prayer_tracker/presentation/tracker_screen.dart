import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/time/timezone_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_calendar.dart';
import 'package:salah_focus/features/ramadan/presentation/ramadan_tracker_section.dart';
import 'package:salah_focus/shared/errors/user_error_message.dart';

class TrackerData {
  const TrackerData({
    required this.entries,
    required this.localNow,
    this.prayerDay,
  });

  final List<PrayerEntry> entries;
  final DateTime localNow;
  final PrayerDay? prayerDay;
}

final trackerDataProvider = FutureProvider<TrackerData>((Ref ref) async {
  final location = ref.watch(
    settingsControllerProvider.select((prefs) => prefs.location),
  );
  final DateTime nowUtc = ref.watch(clockServiceProvider).nowUtc();
  if (location == null) {
    return TrackerData(entries: const <PrayerEntry>[], localNow: nowUtc);
  }

  final day = await ref.watch(todayPrayerDayProvider.future);
  final String timezoneId = day?.timezoneId ?? location.timezoneId;
  final DateTime localNow = TimezoneService.toLocal(nowUtc, timezoneId);
  final DateTime first = DateTime(localNow.year, localNow.month, 1);
  // Include the previous two calendar days even across a month/year boundary.
  final DateTime oldestEditable = DateTime(
    localNow.year,
    localNow.month,
    localNow.day - 2,
  );
  final DateTime start = oldestEditable.isBefore(first)
      ? oldestEditable
      : first;
  final DateTime last = DateTime(localNow.year, localNow.month + 1, 0);
  final List<PrayerEntry> entries = await ref
      .watch(prayerCoordinatorProvider)
      .entriesBetween(_iso(start), _iso(last));

  return TrackerData(entries: entries, localNow: localNow, prayerDay: day);
});

class TrackerScreen extends ConsumerWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = AppStrings.of(context);
    final AsyncValue<TrackerData> tracker = ref.watch(trackerDataProvider);

    Future<void> refresh() async {
      ref.invalidate(todayPrayerDayProvider);
      ref.invalidate(trackerDataProvider);
      await ref.read(trackerDataProvider.future);
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.t('tracker'))),
      body: tracker.when(
        skipLoadingOnReload: true,
        data: (TrackerData data) => _TrackerContent(
          entries: data.entries,
          localNow: data.localNow,
          prayerDay: data.prayerDay,
          onRefresh: refresh,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline_rounded, size: 50),
                const SizedBox(height: 12),
                Text(
                  userErrorMessage(context, error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => refresh(),
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

Future<void> _showTrackerInfo(BuildContext context) => showDialog<void>(
  context: context,
  builder: (BuildContext dialogContext) {
    final AppStrings s = AppStrings.of(dialogContext);
    return AlertDialog(
      title: Text(s.t('trackerInfoTitle')),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(s.t('trackerInfoIntro')),
              const SizedBox(height: 20),
              for (final PrayerStatus status in PrayerStatus.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _StatusExplanation(status: status),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(s.t('close')),
        ),
      ],
    );
  },
);

Future<void> _showTodayInfo(BuildContext context) => showDialog<void>(
  context: context,
  builder: (BuildContext dialogContext) {
    final AppStrings s = AppStrings.of(dialogContext);
    return AlertDialog(
      title: Text(s.t('todayInfoTitle')),
      content: Text(s.t('todayInfoBody')),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(s.t('close')),
        ),
      ],
    );
  },
);

class _StatusExplanation extends StatelessWidget {
  const _StatusExplanation({required this.status});

  final PrayerStatus status;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _StatusIcon(status: status),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _statusLabel(context, status),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                s.t(
                  'status${status.name[0].toUpperCase()}${status.name.substring(1)}Help',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackerContent extends StatelessWidget {
  const _TrackerContent({
    required this.entries,
    required this.localNow,
    required this.prayerDay,
    required this.onRefresh,
  });

  final List<PrayerEntry> entries;
  final DateTime localNow;
  final PrayerDay? prayerDay;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    if (entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
            Center(child: Text(s.t('noData'))),
          ],
        ),
      );
    }

    final DateTime now = localNow;
    final String today = _iso(now);
    final Map<String, List<PrayerEntry>> byDay = <String, List<PrayerEntry>>{};
    for (final PrayerEntry entry in entries) {
      byDay.putIfAbsent(entry.localDate, () => <PrayerEntry>[]).add(entry);
    }

    final List<PrayerEntry> todayEntries =
        byDay[today] ?? const <PrayerEntry>[];
    final int prayed = todayEntries
        .where((PrayerEntry entry) => entry.status == PrayerStatus.prayed)
        .length;
    final double ratio = prayed / 5;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: <Widget>[
          Row(
            key: const ValueKey<String>('tracker-today-heading'),
            children: <Widget>[
              Flexible(
                child: Text(
                  s.t('today'),
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                key: const ValueKey<String>('today-info-button'),
                tooltip: s.t('todayInfoTitle'),
                onPressed: () => _showTodayInfo(context),
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StatsCard(prayed: prayed, ratio: ratio),
          if (prayed == 5)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8, start: 4),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  key: const ValueKey<String>('today-completion-message'),
                  s.t('todayAllPrayersCompleted'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            key: const ValueKey<String>('tracker-week-heading'),
            children: <Widget>[
              Flexible(
                child: Text(
                  s.t('week'),
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                key: const ValueKey<String>('tracker-info-button'),
                tooltip: s.t('trackerInfo'),
                onPressed: () => _showTrackerInfo(context),
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DayCard(
                key: ValueKey<String>(
                  'tracker-day-${_iso(DateTime(now.year, now.month, now.day - i))}',
                ),
                date: _iso(DateTime(now.year, now.month, now.day - i)),
                entries:
                    byDay[_iso(DateTime(now.year, now.month, now.day - i))] ??
                    const <PrayerEntry>[],
                labelKey: const ['today', 'yesterday', 'dayBeforeYesterday'][i],
                isToday: i == 0,
              ),
            ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Text(
                s.t('month'),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 2),
              IconButton(
                key: const ValueKey<String>('month-info-button'),
                tooltip: s.t('monthInfo'),
                onPressed: () => _showMonthInfo(context),
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MonthGrid(
            month: DateTime(now.year, now.month),
            byDay: byDay,
            localNow: now,
          ),
          if (prayerDay != null && RamadanCalendar.isRamadan(prayerDay!))
            const RamadanTrackerSection(),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.prayed, required this.ratio});

  final int prayed;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return Card(
      key: const ValueKey<String>('today-stats-card'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: ratio,
                strokeWidth: 7,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s.t('todayConfirmedPrayers'),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${s.number(prayed)}/${s.number(5)}',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends ConsumerStatefulWidget {
  const _DayCard({
    super.key,
    required this.date,
    required this.entries,
    required this.labelKey,
    this.isToday = false,
  });

  final String date;
  final List<PrayerEntry> entries;
  final String labelKey;
  final bool isToday;

  @override
  ConsumerState<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends ConsumerState<_DayCard> {
  bool _working = false;
  bool _expanded = false;

  Future<void> _changePrayer(PrayerEntry entry) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final bool prayed = entry.status != PrayerStatus.prayed;
      final bool accepted =
          await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              final AppStrings s = AppStrings.of(dialogContext);
              return AlertDialog(
                title: Text(
                  s.t(
                    prayed
                        ? 'confirmPrayerRecordTitle'
                        : 'undoPrayerRecordTitle',
                  ),
                ),
                content: Text(
                  s.t(
                    prayed ? 'confirmPrayerRecordBody' : 'undoPrayerRecordBody',
                    params: {
                      'prayer': entry.type.localizedName(s.locale.languageCode),
                      'date': s.mediumDate(DateTime.parse(entry.localDate)),
                    },
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(s.t('cancel')),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(s.t(prayed ? 'confirmPrayer' : 'yes')),
                  ),
                ],
              );
            },
          ) ??
          false;
      if (!mounted || !accepted) return;
      await ref
          .read(prayerCoordinatorProvider)
          .correctHistoricalPrayer(entry, prayed: prayed);
      if (!mounted) return;
      ref.invalidate(todayPrayerDayProvider);
      ref.invalidate(trackerDataProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userErrorMessage(context, error))),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime parsed = DateTime.parse(widget.date);
    final String locale = Localizations.localeOf(context).languageCode;
    final AppStrings s = AppStrings.of(context);
    final int prayed = widget.entries
        .where((PrayerEntry entry) => entry.status == PrayerStatus.prayed)
        .length;
    final String title = s.fullDate(parsed);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: widget.isToday
          ? Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.08),
              scheme.surface,
            )
          : null,
      shape: widget.isToday
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: scheme.primary, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Column(
          children: <Widget>[
            Semantics(
              button: !widget.isToday,
              expanded: widget.isToday ? null : _expanded,
              child: InkWell(
                key: ValueKey<String>('tracker-header-${widget.date}'),
                borderRadius: BorderRadius.circular(12),
                onTap: widget.isToday
                    ? null
                    : () => setState(() => _expanded = !_expanded),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              s.t(widget.labelKey),
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            title,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${s.number(prayed)}/${s.number(5)}',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!widget.isToday) ...<Widget>[
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.isToday || _expanded) ...<Widget>[
              const SizedBox(height: 10),
              for (final PrayerEntry entry in widget.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: <Widget>[
                      _StatusIcon(status: entry.status),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.type.localizedName(locale))),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: <Widget>[
                              Text(_statusLabel(context, entry.status)),
                              if (entry.editedAtUtc != null)
                                Tooltip(
                                  key: ValueKey<String>('edited-${entry.id}'),
                                  message: s.t('edited'),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: scheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      ...<Widget>[
                        const SizedBox(width: 4),
                        IconButton(
                          key: ValueKey<String>('correct-${entry.id}'),
                          tooltip: entry.status == PrayerStatus.prayed
                              ? s.t('missed')
                              : s.t('prayed'),
                          icon: Icon(
                            entry.status == PrayerStatus.prayed
                                ? Icons.undo_rounded
                                : Icons.check_circle_outline_rounded,
                          ),
                          onPressed: _working
                              ? null
                              : () => _changePrayer(entry),
                        ),
                      ],
                    ],
                  ),
                ),
              if (widget.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(AppStrings.of(context).t('noData')),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.byDay,
    required this.localNow,
  });

  final DateTime month;
  final Map<String, List<PrayerEntry>> byDay;
  final DateTime localNow;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final int days = DateTime(month.year, month.month + 1, 0).day;
    final int prefix = DateTime(month.year, month.month, 1).weekday - 1;
    final int total = prefix + days;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final double cellHeight = (textScaler.scale(20) + textScaler.scale(18) + 20)
        .clamp(58.0, double.infinity);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            mainAxisExtent: cellHeight,
          ),
          itemCount: total,
          itemBuilder: (BuildContext context, int index) {
            if (index < prefix) return const SizedBox.shrink();
            final int day = index - prefix + 1;
            final String key = _iso(DateTime(month.year, month.month, day));
            final List<PrayerEntry> values =
                byDay[key] ?? const <PrayerEntry>[];
            final int prayed = values
                .where(
                  (PrayerEntry entry) => entry.status == PrayerStatus.prayed,
                )
                .length;
            final DateTime date = DateTime(month.year, month.month, day);
            final bool past = date.isBefore(
              DateTime(localNow.year, localNow.month, localNow.day),
            );
            final bool isToday =
                date == DateTime(localNow.year, localNow.month, localNow.day);
            final (Color background, Color foreground) = _calendarColors(
              context,
              prayed: prayed,
              isPast: past,
            );
            return Semantics(
              excludeSemantics: true,
              label:
                  '${isToday ? '${s.t('today')}, ' : ''}${s.number(day)}, ${s.number(prayed)}/${s.number(5)} ${s.t('confirmedPrayers')}',
              child: DecoratedBox(
                key: ValueKey<String>('calendar-$key'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: background,
                  border: isToday
                      ? Border.all(color: scheme.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          s.number(day),
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${s.number(prayed)}/${s.number(5)}',
                          maxLines: 1,
                          softWrap: false,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> _showMonthInfo(BuildContext context) => showDialog<void>(
  context: context,
  builder: (BuildContext dialogContext) {
    final AppStrings s = AppStrings.of(dialogContext);
    final String countExamples =
        '${s.number(0)}/${s.number(5)}  ·  '
        '${s.number(1)}/${s.number(5)}  ·  '
        '${s.number(5)}/${s.number(5)}';
    return AlertDialog(
      title: Text(s.t('monthInfoTitle')),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(s.t('monthInfoOverview')),
              const SizedBox(height: 18),
              Text(
                countExamples,
                style: Theme.of(dialogContext).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(s.t('monthCountHelp')),
              const SizedBox(height: 22),
              _MonthLegendEntry(
                swatch: const _MonthLegendSwatch(
                  key: ValueKey<String>('month-legend-complete'),
                  prayed: 5,
                  isPast: true,
                ),
                label: s.t('monthAllConfirmedHelp'),
              ),
              _MonthLegendEntry(
                swatch: const _MonthLegendSwatch(
                  key: ValueKey<String>('month-legend-partial'),
                  prayed: 1,
                  isPast: true,
                ),
                label: s.t('monthPartiallyConfirmedHelp'),
              ),
              _MonthLegendEntry(
                swatch: const _MonthLegendSwatch(
                  key: ValueKey<String>('month-legend-none'),
                  prayed: 0,
                  isPast: true,
                ),
                label: s.t('monthNoneConfirmedHelp'),
              ),
              _MonthLegendEntry(
                swatch: const _MonthLegendSwatch(
                  key: ValueKey<String>('month-legend-future'),
                  prayed: 0,
                  isPast: false,
                ),
                label: s.t('monthFutureHelp'),
              ),
              _MonthLegendEntry(
                swatch: const _MonthLegendSwatch(
                  key: ValueKey<String>('month-legend-today'),
                  prayed: 0,
                  isPast: false,
                  isToday: true,
                ),
                label: s.t('monthTodayOutlineHelp'),
                bottomPadding: 0,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(s.t('close')),
        ),
      ],
    );
  },
);

class _MonthLegendEntry extends StatelessWidget {
  const _MonthLegendEntry({
    required this.swatch,
    required this.label,
    this.bottomPadding = 14,
  });

  final Widget swatch;
  final String label;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: bottomPadding),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ExcludeSemantics(child: swatch),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

class _MonthLegendSwatch extends StatelessWidget {
  const _MonthLegendSwatch({
    super.key,
    required this.prayed,
    required this.isPast,
    this.isToday = false,
  });

  final int prayed;
  final bool isPast;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = _calendarColors(
      context,
      prayed: prayed,
      isPast: isPast,
    );
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: background,
        border: isToday
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        AppStrings.of(context).number(prayed),
        style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final PrayerStatus status;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (status) {
      PrayerStatus.prayed => (
        Icons.check_circle_rounded,
        Theme.of(context).colorScheme.primary,
      ),
      PrayerStatus.skipped => (
        Icons.remove_circle_outline_rounded,
        Theme.of(context).colorScheme.outline,
      ),
      PrayerStatus.missed => (
        Icons.help_outline_rounded,
        Theme.of(context).colorScheme.error,
      ),
      PrayerStatus.snoozed => (
        Icons.snooze_rounded,
        Theme.of(context).colorScheme.tertiary,
      ),
      _ => (Icons.circle_outlined, Theme.of(context).colorScheme.outline),
    };
    return Icon(icon, color: color, size: 20);
  }
}

String _statusLabel(BuildContext context, PrayerStatus status) {
  final AppStrings s = AppStrings.of(context);
  return switch (status) {
    PrayerStatus.prayed => s.t('prayed'),
    PrayerStatus.skipped => s.t('skipped'),
    PrayerStatus.missed => s.t('missed'),
    PrayerStatus.snoozed => s.t('snoozed'),
    PrayerStatus.pending => s.t('pending'),
    PrayerStatus.active => s.t('active'),
    PrayerStatus.upcoming => s.t('upcoming'),
  };
}

(Color, Color) _calendarColors(
  BuildContext context, {
  required int prayed,
  required bool isPast,
}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final bool dark = scheme.brightness == Brightness.dark;
  // Pair every status background with its own readable foreground.
  if (prayed >= 5) {
    return dark
        ? (const Color(0xFF183F32), const Color(0xFFB7F3D3))
        : (const Color(0xFFD7F3DF), const Color(0xFF153D28));
  }
  if (prayed > 0) {
    return dark
        ? (const Color(0xFF3C2E16), const Color(0xFFFFE0A3))
        : (const Color(0xFFFFF0C2), const Color(0xFF573D00));
  }
  if (isPast) return (scheme.errorContainer, scheme.onErrorContainer);
  return (scheme.surfaceContainerHighest, scheme.onSurface);
}

String _iso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
