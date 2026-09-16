import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/features/ramadan/application/ramadan_providers.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_goal.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_record.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';

class RamadanTrackerSection extends ConsumerWidget {
  const RamadanTrackerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled = ref.watch(
      settingsControllerProvider.select(
        (preferences) => preferences.ramadanSettings.enabled,
      ),
    );
    if (!enabled) return const SizedBox.shrink();
    final AsyncValue<RamadanTrackerData?> value = ref.watch(
      ramadanTrackerDataProvider,
    );
    return value.when(
      data: (RamadanTrackerData? data) => data == null
          ? const SizedBox.shrink()
          : _RamadanTrackerContent(data: data),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _RamadanTrackerContent extends ConsumerWidget {
  const _RamadanTrackerContent({required this.data});

  final RamadanTrackerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = AppStrings.of(context);
    final Map<int, RamadanRecord> byDay = <int, RamadanRecord>{
      for (final RamadanRecord record in data.records) record.hijriDay: record,
    };
    final int fasted = data.records
        .where((record) => record.fastingStatus == FastingStatus.fasted)
        .length;
    return Column(
      key: const ValueKey<String>('ramadan-tracker-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                s.t('ramadanTracker'),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              key: const ValueKey<String>('ramadan-tracker-info'),
              tooltip: s.t('ramadanTrackerInfo'),
              onPressed: () => _showRamadanInfo(context),
              icon: const Icon(Icons.info_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.t(
                    'fastingProgress',
                    params: <String, String>{
                      'fasted': s.number(fasted),
                      'days': s.number(data.today.ramadanDate.day),
                    },
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final int columns = constraints.maxWidth >= 400 ? 6 : 5;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 30,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final int day = index + 1;
                        final bool future = day > data.today.ramadanDate.day;
                        return _RamadanDayCell(
                          day: day,
                          record: byDay[day],
                          isFuture: future,
                          isToday: day == data.today.ramadanDate.day,
                          onTap: future
                              ? null
                              : () => _editDay(context, ref, day, byDay[day]),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _RamadanGoalsCard(data: data),
      ],
    );
  }

  Future<void> _editDay(
    BuildContext context,
    WidgetRef ref,
    int hijriDay,
    RamadanRecord? existing,
  ) async {
    final DateTime today = DateTime.parse(data.today.prayerDay.localDate);
    final DateTime selected = today.add(
      Duration(days: hijriDay - data.today.ramadanDate.day),
    );
    final String localDate = _iso(selected);
    final RamadanRecord initial =
        existing ??
        await ref.read(ramadanRepositoryProvider).recordForDate(localDate) ??
        RamadanRecord(
          localDate: localDate,
          hijriYear: data.today.ramadanDate.year,
          hijriDay: hijriDay,
        );
    if (!context.mounted) return;
    final RamadanRecord? result = await showDialog<RamadanRecord>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _RamadanDayDialog(record: initial, day: hijriDay),
    );
    if (result == null) return;
    await ref.read(ramadanControllerProvider).saveRecord(result);
    _refresh(ref);
  }
}

class _RamadanDayCell extends StatelessWidget {
  const _RamadanDayCell({
    required this.day,
    required this.record,
    required this.isFuture,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final RamadanRecord? record;
  final bool isFuture;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final FastingStatus status =
        record?.fastingStatus ?? FastingStatus.notRecorded;
    final IconData icon = isFuture
        ? Icons.schedule_rounded
        : switch (status) {
            FastingStatus.fasted => Icons.check_rounded,
            FastingStatus.didNotFast => Icons.horizontal_rule_rounded,
            FastingStatus.notRecorded => Icons.circle_outlined,
          };
    final String statusLabel = isFuture
        ? s.t('futureDay')
        : switch (status) {
            FastingStatus.fasted => s.t('fasted'),
            FastingStatus.didNotFast => s.t('didNotFast'),
            FastingStatus.notRecorded => s.t('notRecorded'),
          };
    final Color color = isFuture
        ? Theme.of(context).colorScheme.outline
        : status == FastingStatus.fasted
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      label: '${s.number(day)}, $statusLabel',
      button: onTap != null,
      child: Material(
        key: ValueKey<String>('ramadan-day-$day'),
        color: status == FastingStatus.fasted && !isFuture
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isToday
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    s.number(day),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Icon(icon, size: 21, color: color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RamadanDayDialog extends StatefulWidget {
  const _RamadanDayDialog({required this.record, required this.day});

  final RamadanRecord record;
  final int day;

  @override
  State<_RamadanDayDialog> createState() => _RamadanDayDialogState();
}

class _RamadanDayDialogState extends State<_RamadanDayDialog> {
  late RamadanRecord _record = widget.record;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final ramadanSettings = ref.watch(
          settingsControllerProvider.select(
            (preferences) => preferences.ramadanSettings,
          ),
        );
        return AlertDialog(
          title: Text('${s.t('editRamadanDay')} ${s.number(widget.day)}'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s.t('fasting'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  for (final FastingStatus status in FastingStatus.values)
                    ListTile(
                      leading: Icon(
                        _record.fastingStatus == status
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                      ),
                      title: Text(switch (status) {
                        FastingStatus.fasted => s.t('fasted'),
                        FastingStatus.didNotFast => s.t('didNotFast'),
                        FastingStatus.notRecorded => s.t('notRecorded'),
                      }),
                      onTap: () => setState(
                        () => _record = _record.copyWith(fastingStatus: status),
                      ),
                    ),
                  if (ramadanSettings.tarawihTrackingEnabled) ...<Widget>[
                    const Divider(),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.t('tarawih')),
                      subtitle: Text(
                        _record.tarawihCompleted == true
                            ? s.t('completed')
                            : s.t('notRecorded'),
                      ),
                      value: _record.tarawihCompleted == true,
                      onChanged: (bool? value) => setState(
                        () => _record = _record.copyWith(
                          tarawihCompleted: value == true ? true : null,
                          clearTarawih: value != true,
                        ),
                      ),
                    ),
                  ],
                  if (ramadanSettings.qiyamTrackingEnabled) ...<Widget>[
                    const Divider(),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.t('qiyam')),
                      subtitle: Text(
                        _record.qiyamCompleted == true
                            ? s.t('completed')
                            : s.t('notRecorded'),
                      ),
                      value: _record.qiyamCompleted == true,
                      onChanged: (bool? value) => setState(
                        () => _record = _record.copyWith(
                          qiyamCompleted: value == true ? true : null,
                          clearQiyam: value != true,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_record),
              child: Text(s.t('save')),
            ),
          ],
        );
      },
    );
  }
}

class _RamadanGoalsCard extends ConsumerWidget {
  const _RamadanGoalsCard({required this.data});

  final RamadanTrackerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = AppStrings.of(context);
    final int completed = data.goals
        .where((RamadanGoal goal) => data.completedGoalIds.contains(goal.id))
        .length;
    return Card(
      key: const ValueKey<String>('ramadan-goals-card'),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    s.t('ramadanGoals'),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: s.t('addGoal'),
                  onPressed: () => _addGoal(context, ref),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            Text(
              data.goals.isEmpty
                  ? s.t('noRamadanGoals')
                  : s.t(
                      'goalsCompletedToday',
                      params: <String, String>{
                        'completed': s.number(completed),
                        'total': s.number(data.goals.length),
                      },
                    ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (data.goals.isNotEmpty) const SizedBox(height: 8),
            for (final RamadanGoal goal in data.goals)
              CheckboxListTile(
                key: ValueKey<String>('ramadan-goal-${goal.id}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(goal.title),
                value: data.completedGoalIds.contains(goal.id),
                onChanged: (bool? value) =>
                    _setCompleted(ref, goal, value == true),
                secondary: PopupMenuButton<String>(
                  tooltip: s.t('editGoal'),
                  onSelected: (String action) {
                    if (action == 'edit') _editGoal(context, ref, goal);
                    if (action == 'delete') _deleteGoal(context, ref, goal);
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text(s.t('editGoal')),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(s.t('deleteGoal')),
                        ),
                      ],
                ),
              ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => _addGoal(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(s.t('addGoal')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setCompleted(
    WidgetRef ref,
    RamadanGoal goal,
    bool completed,
  ) async {
    await ref
        .read(ramadanControllerProvider)
        .setGoalCompleted(
          goal: goal,
          localDate: data.today.prayerDay.localDate,
          completed: completed,
        );
    _refresh(ref);
  }

  Future<void> _addGoal(BuildContext context, WidgetRef ref) async {
    final String? title = await showDialog<String>(
      context: context,
      builder: (_) => const _GoalEditorDialog(),
    );
    if (title == null) return;
    await ref.read(ramadanControllerProvider).addGoal(title);
    _refresh(ref);
  }

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref,
    RamadanGoal goal,
  ) async {
    final String? title = await showDialog<String>(
      context: context,
      builder: (_) => _GoalEditorDialog(goal: goal),
    );
    if (title == null) return;
    await ref.read(ramadanControllerProvider).updateGoal(goal, title);
    _refresh(ref);
  }

  Future<void> _deleteGoal(
    BuildContext context,
    WidgetRef ref,
    RamadanGoal goal,
  ) async {
    final AppStrings s = AppStrings.of(context);
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(s.t('deleteGoal')),
            content: SingleChildScrollView(
              child: Text(s.t('goalDeleteConfirm')),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(s.t('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(s.t('deleteGoal')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await ref.read(ramadanControllerProvider).deleteGoal(goal);
    _refresh(ref);
  }
}

class _GoalEditorDialog extends StatefulWidget {
  const _GoalEditorDialog({this.goal});

  final RamadanGoal? goal;

  @override
  State<_GoalEditorDialog> createState() => _GoalEditorDialogState();
}

class _GoalEditorDialogState extends State<_GoalEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.goal?.title ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return AlertDialog(
      title: Text(s.t(widget.goal == null ? 'addGoal' : 'editGoal')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            maxLength: 80,
            autofocus: true,
            decoration: InputDecoration(
              labelText: s.t('goalName'),
              hintText: s.t('goalNameHint'),
            ),
            validator: (String? value) =>
                value == null || value.trim().isEmpty ? s.t('goalName') : null,
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: Text(s.t('save')),
        ),
      ],
    );
  }
}

Future<void> _showRamadanInfo(BuildContext context) => showDialog<void>(
  context: context,
  builder: (BuildContext dialogContext) {
    final AppStrings s = AppStrings.of(dialogContext);
    return AlertDialog(
      title: Text(s.t('ramadanTrackerInfo')),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(s.t('ramadanTrackerHelp')),
              const SizedBox(height: 16),
              for (final String key in <String>[
                'ramadanSymbolFasted',
                'ramadanSymbolDidNotFast',
                'ramadanSymbolNotRecorded',
                'ramadanSymbolFuture',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(s.t(key)),
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

String _iso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

void _refresh(WidgetRef ref) {
  ref.invalidate(ramadanTodayProvider);
  ref.invalidate(ramadanTrackerDataProvider);
}
