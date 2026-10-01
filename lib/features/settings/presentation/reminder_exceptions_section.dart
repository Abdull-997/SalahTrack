import 'package:flutter/material.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_times/domain/reminder_exception.dart';
import 'package:salah_focus/shared/errors/user_error_message.dart';

class ReminderExceptionsSection extends StatefulWidget {
  const ReminderExceptionsSection({
    required this.settings,
    required this.onChanged,
    super.key,
  });

  final PrayerSettings settings;
  final Future<void> Function(PrayerSettings settings) onChanged;

  @override
  State<ReminderExceptionsSection> createState() =>
      _ReminderExceptionsSectionState();
}

class _ReminderExceptionsSectionState extends State<ReminderExceptionsSection> {
  bool _saving = false;

  Future<void> _save(List<ReminderException> exceptions) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onChanged(
        widget.settings.copyWith(reminderExceptions: exceptions),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userErrorMessage(context, error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit(ReminderException? existing) async {
    final List<PrayerType> available = PrayerType.values
        .where(
          (PrayerType type) =>
              type == existing?.prayer ||
              !widget.settings.reminderExceptions.any(
                (ReminderException item) => item.prayer == type,
              ),
        )
        .toList();
    if (available.isEmpty) return;
    PrayerType prayer = existing?.prayer ?? available.first;
    bool everyDay = existing?.everyDay ?? true;
    final Set<int> weekdays = <int>{...?existing?.weekdays};
    final ReminderException? result = await showDialog<ReminderException>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter update) {
          final AppStrings s = AppStrings.of(context);
          return AlertDialog(
            title: Text(
              s.t(existing == null ? 'addException' : 'editException'),
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DropdownButtonFormField<PrayerType>(
                      key: const ValueKey<String>('exception-prayer'),
                      initialValue: prayer,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: s.t('disableRemindersForPrayer'),
                      ),
                      items: <DropdownMenuItem<PrayerType>>[
                        for (final PrayerType type in available)
                          DropdownMenuItem<PrayerType>(
                            value: type,
                            child: Text(
                              type.localizedName(s.locale.languageCode),
                            ),
                          ),
                      ],
                      onChanged: (PrayerType? value) {
                        if (value != null) update(() => prayer = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<bool>(
                      key: const ValueKey<String>('exception-repeat'),
                      initialValue: everyDay,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: s.t('weekdays')),
                      items: <DropdownMenuItem<bool>>[
                        DropdownMenuItem(
                          value: true,
                          child: Text(s.t('everyDay')),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text(s.t('selectedWeekdays')),
                        ),
                      ],
                      onChanged: (bool? value) {
                        if (value != null) update(() => everyDay = value);
                      },
                    ),
                    if (!everyDay) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(s.t('weekdays')),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: <Widget>[
                          for (int day = 1; day <= 7; day++)
                            FilterChip(
                              key: ValueKey<String>('exception-weekday-$day'),
                              label: Text(
                                s.date(DateTime(2024, 1, day), pattern: 'EEE'),
                              ),
                              selected: weekdays.contains(day),
                              onSelected: (bool selected) => update(() {
                                if (selected) {
                                  weekdays.add(day);
                                } else {
                                  weekdays.remove(day);
                                }
                              }),
                            ),
                        ],
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
                onPressed: !everyDay && weekdays.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                        ReminderException(
                          prayer: prayer,
                          weekdays: everyDay
                              ? const <int>{}
                              : Set<int>.of(weekdays),
                        ),
                      ),
                child: Text(s.t('save')),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted || result == null) return;
    final List<ReminderException> next = <ReminderException>[
      for (final ReminderException item in widget.settings.reminderExceptions)
        if (item.prayer != existing?.prayer) item,
      result,
    ];
    await _save(next);
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final List<ReminderException> exceptions =
        <ReminderException>[...widget.settings.reminderExceptions]..sort(
          (ReminderException a, ReminderException b) =>
              a.prayer.index.compareTo(b.prayer.index),
        );
    return Card(
      child: Column(
        children: <Widget>[
          if (exceptions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(s.t('noReminderExceptions')),
            ),
          for (final ReminderException exception in exceptions) ...<Widget>[
            ListTile(
              key: ValueKey<String>('exception-${exception.prayer.name}'),
              leading: const Icon(Icons.notifications_off_outlined),
              title: Text(
                exception.prayer.localizedName(s.locale.languageCode),
              ),
              subtitle: Text(
                exception.everyDay
                    ? s.t('everyDay')
                    : (exception.weekdays.toList()..sort())
                          .map(
                            (int day) =>
                                s.date(DateTime(2024, 1, day), pattern: 'EEE'),
                          )
                          .join(', '),
              ),
              onTap: _saving ? null : () => _edit(exception),
              trailing: IconButton(
                key: ValueKey<String>(
                  'delete-exception-${exception.prayer.name}',
                ),
                tooltip: s.t('deleteException'),
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _saving
                    ? null
                    : () => _save(<ReminderException>[
                        for (final ReminderException item in exceptions)
                          if (item.prayer != exception.prayer) item,
                      ]),
              ),
            ),
            const Divider(height: 1),
          ],
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextButton.icon(
              key: const ValueKey<String>('add-reminder-exception'),
              onPressed:
                  _saving || exceptions.length == PrayerType.values.length
                  ? null
                  : () => _edit(null),
              icon: const Icon(Icons.add_rounded),
              label: Text(s.t('addException')),
            ),
          ),
          if (_saving) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
