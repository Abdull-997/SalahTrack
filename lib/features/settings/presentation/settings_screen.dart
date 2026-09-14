import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_language.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/location/location_suggestions.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/presentation/language_selection_screen.dart';
import 'package:salah_focus/features/settings/presentation/notification_settings_screen.dart';
import 'package:salah_focus/shared/errors/user_error_message.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final prefs = ref.watch(settingsControllerProvider);
    final PrayerSettings settings = prefs.prayerSettings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('settings')),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('settings-info-button'),
            tooltip: s.t('settingsInfo'),
            onPressed: _showSettingsInfo,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          _SectionTitle(
            title: s.t('prayerTimes'),
            icon: Icons.schedule_rounded,
          ),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(s.t('location')),
                  subtitle: Text(
                    prefs.location == null
                        ? s.t('needLocation')
                        : prefs.location!.label.isEmpty
                        ? s.t('currentLocation')
                        : prefs.location!.label,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _working ? null : _changeLocation,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calculate_outlined),
                  title: Text(s.t('calculationMethod')),
                  subtitle: Text(
                    _localizedCalculationMethodName(
                      settings.calculationMethodId,
                      s.locale.languageCode,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _chooseCalculationMethod(settings),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.balance_rounded),
                  title: Text(s.t('madhhab')),
                  subtitle: Text(
                    settings.madhhab == AsrMadhhab.hanafi
                        ? s.t('hanafi')
                        : s.t('standard'),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _chooseMadhhab(settings),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.public_rounded),
                  title: Text(s.t('highLatitude')),
                  subtitle: Text(
                    _localizedHighLatitudeName(
                      settings.highLatitudeRule,
                      s.locale.languageCode,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _chooseHighLatitude(settings),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: Text(s.t('manualAdjustments')),
                  subtitle: Text(_localizedAdjustmentsSummary(settings, s)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _editAdjustments(settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: s.t('permissions'),
            icon: Icons.notifications_active_outlined,
          ),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(s.t('notificationPermission')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _working ? null : _requestNotifications,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alarm_rounded),
                  title: Text(s.t('exactAlarmPermission')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _working ? null : _requestExactAlarms,
                ),
                if (!kIsWeb &&
                    defaultTargetPlatform ==
                        TargetPlatform.android) ...<Widget>[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.fullscreen_rounded),
                    title: Text(s.t('fullScreenAlarmPermission')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _working ? null : _requestFullScreenAlarms,
                  ),
                ],
                const Divider(height: 1),
                _SliderTile(
                  title: s.t('gracePeriod'),
                  valueLabel: s.minutes(settings.gracePeriodMinutes),
                  value: settings.gracePeriodMinutes.toDouble(),
                  min: 0,
                  max: 120,
                  divisions: 24,
                  onChanged: (double value) => _savePrayerSettings(
                    settings.copyWith(gracePeriodMinutes: value.round()),
                  ),
                ),
                const Divider(height: 1),
                _SliderTile(
                  title: s.t('snoozeDuration'),
                  valueLabel: s.minutes(settings.snoozeMinutes),
                  value: settings.snoozeMinutes.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  onChanged: (double value) => _savePrayerSettings(
                    settings.copyWith(snoozeMinutes: value.round()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(s.t('maxSnoozes')),
                  subtitle: Text(
                    settings.maxSnoozes == null
                        ? s.t('unlimited')
                        : s.number(settings.maxSnoozes!),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _chooseMaxSnoozes(settings),
                ),
                SwitchListTile(
                  title: Text(s.t('softReminder')),
                  value: settings.softReminderAfterSkip,
                  onChanged: (bool value) => _savePrayerSettings(
                    settings.copyWith(softReminderAfterSkip: value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: s.t('confirmationText'),
            icon: Icons.check_circle_outline_rounded,
          ),
          Card(
            child: ListTile(
              title: Text(s.t('confirmationText')),
              subtitle: Text(settings.confirmationText),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editConfirmationText(settings),
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(title: s.t('theme'), icon: Icons.palette_outlined),
          Card(
            child: Column(
              children: <Widget>[
                _RadioLikeTile(
                  title: s.t('system'),
                  selected: prefs.themeMode == ThemeMode.system.name,
                  onTap: () => ref
                      .read(settingsControllerProvider.notifier)
                      .setThemeMode(ThemeMode.system),
                ),
                _RadioLikeTile(
                  title: s.t('light'),
                  selected: prefs.themeMode == ThemeMode.light.name,
                  onTap: () => ref
                      .read(settingsControllerProvider.notifier)
                      .setThemeMode(ThemeMode.light),
                ),
                _RadioLikeTile(
                  title: s.t('dark'),
                  selected: prefs.themeMode == ThemeMode.dark.name,
                  onTap: () => ref
                      .read(settingsControllerProvider.notifier)
                      .setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(title: s.t('language'), icon: Icons.language_rounded),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text(s.t('languageSelect')),
              subtitle: Text(languageName(prefs.localeCode)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _working
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LanguageSelectionScreen(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettingsInfo() => showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      final AppStrings s = AppStrings.of(dialogContext);
      final String language = s.locale.languageCode;
      final bool showsFullScreenPermission =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      return AlertDialog(
        title: Text(s.t('settingsInfoTitle')),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SettingsHelpGroup(
                  title: s.t('prayerTimes'),
                  items: <_SettingsHelpItem>[
                    _SettingsHelpItem(
                      title: s.t('location'),
                      description: s.t('locationHelp'),
                    ),
                    _SettingsHelpItem(
                      title: s.t('calculationMethod'),
                      description: s.t('calculationMethodHelp'),
                    ),
                    _SettingsHelpItem(
                      title: s.t('madhhab'),
                      description: s.t('asrCalculationHelp'),
                    ),
                    _SettingsHelpItem(
                      title: s.t('standard'),
                      description: s.t('standardAsrHelp'),
                    ),
                    _SettingsHelpItem(
                      title: s.t('hanafi'),
                      description: s.t('hanafiAsrHelp'),
                    ),
                    _SettingsHelpItem(
                      title: s.t('highLatitude'),
                      description: s.t('highLatitudeHelp'),
                    ),
                    for (final HighLatitudeRule rule in HighLatitudeRule.values)
                      _SettingsHelpItem(
                        title: _localizedHighLatitudeName(rule, language),
                        description: s.t(
                          'highLatitude${rule.name[0].toUpperCase()}${rule.name.substring(1)}Help',
                        ),
                      ),
                    _SettingsHelpItem(
                      title: s.t('manualAdjustments'),
                      description: s.t('minuteAdjustmentsHelp'),
                    ),
                  ],
                ),
                _SettingsHelpGroup(
                  title: s.t('prayerReminders'),
                  items: <_SettingsHelpItem>[
                    _SettingsHelpItem(
                      title: s.t('gracePeriod'),
                      description: s.t('gracePeriodHelp'),
                    ),
                    _SettingsHelpItem(
                      title: s.t('snoozeDuration'),
                      description: s.t('snoozeDurationHelp'),
                    ),
                    _SettingsHelpItem(
                      title: s.t('maxSnoozes'),
                      description: s.t('maxSnoozesHelp'),
                    ),
                    _SettingsHelpItem(
                      title: s.t('softReminder'),
                      description: s.t('softReminderHelp'),
                    ),
                    _SettingsHelpItem(
                      title: s.t('confirmationText'),
                      description: s.t('confirmationTextHelp'),
                    ),
                  ],
                ),
                _SettingsHelpGroup(
                  title: s.t('permissions'),
                  bottomPadding: 0,
                  items: <_SettingsHelpItem>[
                    _SettingsHelpItem(
                      title: s.t('notificationPermission'),
                      description: s.t('notificationPermissionHelp'),
                    ),
                    _SettingsHelpItem(
                      title: s.t('exactAlarmPermission'),
                      description: s.t('exactAlarmPermissionHelp'),
                    ),
                    if (showsFullScreenPermission)
                      _SettingsHelpItem(
                        title: s.t('fullScreenAlarmPermission'),
                        description: s.t('fullScreenAlarmPermissionHelp'),
                      ),
                  ],
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

  Future<void> _changeLocation() async {
    final AppStrings s = AppStrings.of(context);
    final String? choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.my_location_rounded),
              title: Text(s.t('useLocation')),
              onTap: () => Navigator.of(context).pop('gps'),
            ),
            ListTile(
              leading: const Icon(Icons.location_city_rounded),
              title: Text(s.t('chooseCity')),
              onTap: () => Navigator.of(context).pop('manual'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'gps') {
      await _run(() async {
        final UserLocation location = await ref
            .read(locationServiceProvider)
            .currentLocation(
              deviceTimezoneId: ref.read(deviceTimezoneIdProvider),
              languageCode: AppStrings.of(context).locale.languageCode,
            );
        await ref
            .read(settingsControllerProvider.notifier)
            .setLocation(location);
        ref.invalidate(todayPrayerDayProvider);
      });
      return;
    }
    await _manualLocationDialog();
  }

  Future<void> _manualLocationDialog() async {
    final AppStrings s = AppStrings.of(context);
    final TextEditingController city = TextEditingController();
    final TextEditingController country = TextEditingController();
    final bool accepted =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) =>
                AlertDialog(
                  title: Text(s.t('chooseCity')),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextField(
                          controller: city,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(labelText: s.t('city')),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: country,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: s.t('country'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              locationSuggestionsFor(s.locale.languageCode)
                                  .map(
                                    (LocationSuggestion suggestion) =>
                                        ActionChip(
                                          label: Text(suggestion.label),
                                          onPressed: () => setDialogState(() {
                                            city.text = suggestion.city;
                                            country.text = suggestion.country;
                                          }),
                                        ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(s.t('cancel')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(s.t('save')),
                    ),
                  ],
                ),
          ),
        ) ??
        false;
    final String cityValue = city.text.trim();
    final String countryValue = country.text.trim();
    city.dispose();
    country.dispose();
    if (!accepted || cityValue.isEmpty || countryValue.isEmpty) return;
    await _run(() async {
      final UserLocation location = await ref
          .read(locationServiceProvider)
          .geocodeManual(
            city: cityValue,
            country: countryValue,
            deviceTimezoneId: ref.read(deviceTimezoneIdProvider),
            languageCode: AppStrings.of(context).locale.languageCode,
          );
      await ref.read(settingsControllerProvider.notifier).setLocation(location);
      ref.invalidate(todayPrayerDayProvider);
    });
  }

  Future<void> _chooseCalculationMethod(PrayerSettings current) async {
    const Map<int, String> methods = <int, String>{
      3: 'Muslim World League',
      2: 'ISNA',
      4: 'Umm Al-Qura, Makkah',
      5: 'Egyptian General Authority',
      1: 'University of Karachi',
      13: 'Diyanet İşleri Başkanlığı',
    };
    final int? selected = await showDialog<int>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(AppStrings.of(context).t('calculationMethod')),
        children: <Widget>[
          _DialogExplanation(
            text: AppStrings.of(context).t('calculationMethodHelp'),
          ),
          ...methods.entries.map(
            (MapEntry<int, String> entry) => SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(entry.key),
              child: _DialogChoice(
                selected: entry.key == current.calculationMethodId,
                label: _localizedCalculationMethodName(
                  entry.key,
                  AppStrings.of(context).locale.languageCode,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      await _savePrayerSettings(
        current.copyWith(calculationMethodId: selected),
      );
    }
  }

  Future<void> _chooseMadhhab(PrayerSettings current) async {
    final AppStrings s = AppStrings.of(context);
    final AsrMadhhab? selected = await showDialog<AsrMadhhab>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(s.t('madhhab')),
        children: <Widget>[
          _DialogExplanation(text: s.t('asrCalculationHelp')),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(AsrMadhhab.standard),
            child: _DialogChoice(
              selected: current.madhhab == AsrMadhhab.standard,
              label: s.t('standard'),
              description: s.t('standardAsrHelp'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(AsrMadhhab.hanafi),
            child: _DialogChoice(
              selected: current.madhhab == AsrMadhhab.hanafi,
              label: s.t('hanafi'),
              description: s.t('hanafiAsrHelp'),
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      await _savePrayerSettings(current.copyWith(madhhab: selected));
    }
  }

  Future<void> _chooseHighLatitude(PrayerSettings current) async {
    final HighLatitudeRule? selected = await showDialog<HighLatitudeRule>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(AppStrings.of(context).t('highLatitude')),
        children: <Widget>[
          _DialogExplanation(
            text: AppStrings.of(context).t('highLatitudeHelp'),
          ),
          ...HighLatitudeRule.values.map(
            (HighLatitudeRule rule) => SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(rule),
              child: _DialogChoice(
                selected: rule == current.highLatitudeRule,
                label: _localizedHighLatitudeName(
                  rule,
                  AppStrings.of(context).locale.languageCode,
                ),
                description: AppStrings.of(context).t(
                  'highLatitude${rule.name[0].toUpperCase()}${rule.name.substring(1)}Help',
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      await _savePrayerSettings(current.copyWith(highLatitudeRule: selected));
    }
  }

  Future<void> _editAdjustments(PrayerSettings current) async {
    final Map<PrayerType, int> values = <PrayerType, int>{
      for (final PrayerType type in PrayerType.values)
        type: current.adjustmentFor(type),
    };
    final bool accepted =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) =>
                AlertDialog(
                  title: Text(AppStrings.of(context).t('manualAdjustments')),
                  content: SizedBox(
                    width: 420,
                    child: ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        Text(AppStrings.of(context).t('minuteAdjustmentsHelp')),
                        const SizedBox(height: 16),
                        ...PrayerType.values.map(
                          (PrayerType type) => Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  type.localizedName(
                                    Localizations.localeOf(context)
                                        .languageCode,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: (values[type] ?? 0) <= -60
                                    ? null
                                    : () => setDialogState(
                                        () => values[type] =
                                            (values[type] ?? 0) - 1,
                                      ),
                                icon: const Icon(Icons.remove_rounded),
                              ),
                              SizedBox(
                                width: 64,
                                child: Text(
                                  AppStrings.of(context)
                                      .minutes(values[type] ?? 0),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                onPressed: (values[type] ?? 0) >= 60
                                    ? null
                                    : () => setDialogState(
                                        () => values[type] =
                                            (values[type] ?? 0) + 1,
                                      ),
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(AppStrings.of(context).t('cancel')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(AppStrings.of(context).t('save')),
                    ),
                  ],
                ),
          ),
        ) ??
        false;
    if (accepted) {
      await _savePrayerSettings(current.copyWith(adjustments: values));
    }
  }

  Future<void> _chooseMaxSnoozes(PrayerSettings current) async {
    final int? value = await showDialog<int>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(AppStrings.of(context).t('maxSnoozes')),
        children: <Widget>[
          _DialogExplanation(text: AppStrings.of(context).t('maxSnoozesHelp')),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(-1),
            child: Text(AppStrings.of(context).t('unlimited')),
          ),
          for (int count = 1; count <= 5; count++)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(count),
              child: Text(AppStrings.of(context).number(count)),
            ),
        ],
      ),
    );
    if (value == null) return;
    if (value == -1) {
      await _savePrayerSettings(current.copyWith(clearMaxSnoozes: true));
    } else {
      await _savePrayerSettings(current.copyWith(maxSnoozes: value));
    }
  }

  Future<void> _editConfirmationText(PrayerSettings current) async {
    final TextEditingController controller = TextEditingController(
      text: current.confirmationText,
    );
    final bool accepted =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(AppStrings.of(context).t('confirmationText')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(AppStrings.of(context).t('confirmationTextHelp')),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLength: 80,
                  decoration: InputDecoration(
                    hintText: AppStrings.of(context).t('confirmPrayer'),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppStrings.of(context).t('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppStrings.of(context).t('save')),
              ),
            ],
          ),
        ) ??
        false;
    final String text = controller.text.trim();
    controller.dispose();
    if (accepted && text.isNotEmpty) {
      await _savePrayerSettings(current.copyWith(confirmationText: text));
    }
  }

  Future<void> _requestNotifications() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationSettingsScreen(),
      ),
    );
    if (mounted) ref.invalidate(todayPrayerDayProvider);
  }

  Future<void> _requestExactAlarms() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationSettingsScreen.exactAlarms(),
      ),
    );
    if (mounted) ref.invalidate(todayPrayerDayProvider);
  }

  Future<void> _requestFullScreenAlarms() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationSettingsScreen.fullScreenAlarms(),
      ),
    );
    if (mounted) ref.invalidate(todayPrayerDayProvider);
  }

  Future<void> _savePrayerSettings(PrayerSettings settings) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setPrayerSettings(settings);
    ref.invalidate(todayPrayerDayProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userErrorMessage(context, error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  String _localizedCalculationMethodName(int id, String language) {
    final Map<int, String> names = switch (language) {
      'tr' => const <int, String>{
        1: 'Karaçi Üniversitesi',
        2: 'Kuzey Amerika İslam Topluluğu',
        3: 'Dünya İslam Birliği',
        4: 'Ümmü’l-Kurâ Üniversitesi, Mekke',
        5: 'Mısır Genel Harita Kurumu',
        13: 'Diyanet İşleri Başkanlığı',
      },
      'fr' => const <int, String>{
        1: 'Université de Karachi',
        2: 'Société islamique d’Amérique du Nord',
        3: 'Ligue islamique mondiale',
        4: 'Université Oumm al-Qoura, La Mecque',
        5: 'Autorité générale égyptienne de topographie',
        13: 'Présidence turque des affaires religieuses',
      },
      'es' => const <int, String>{
        1: 'Universidad de Karachi',
        2: 'Sociedad Islámica de América del Norte',
        3: 'Liga del Mundo Islámico',
        4: 'Universidad Umm al-Qura, La Meca',
        5: 'Autoridad General Egipcia de Topografía',
        13: 'Presidencia turca de Asuntos Religiosos',
      },
      'de' => const <int, String>{
        1: 'Universität Karachi',
        2: 'Islamische Gesellschaft Nordamerikas',
        4: 'Umm-al-Qura-Universität, Mekka',
        5: 'Ägyptische Allgemeine Vermessungsbehörde',
        13: 'Türkisches Präsidium für Religionsangelegenheiten',
        3: 'Muslimische Weltliga',
      },
      'ar' => const <int, String>{
        1: 'جامعة كراتشي',
        2: 'الجمعية الإسلامية لأمريكا الشمالية',
        4: 'جامعة أم القرى، مكة',
        5: 'الهيئة المصرية العامة للمساحة',
        13: 'رئاسة الشؤون الدينية التركية',
        3: 'رابطة العالم الإسلامي',
      },
      'ur' => const <int, String>{
        1: 'جامعہ کراچی',
        2: 'اسلامک سوسائٹی آف نارتھ امریکہ',
        4: 'جامعہ ام القریٰ، مکہ',
        5: 'مصری جنرل اتھارٹی برائے سروے',
        13: 'ترکیہ امورِ مذہبیہ',
        3: 'مسلم ورلڈ لیگ',
      },
      'ps' => const <int, String>{
        1: 'د کراچۍ پوهنتون',
        2: 'د شمالي امریکا اسلامي ټولنه',
        4: 'د ام القرى پوهنتون، مکه',
        5: 'د مصر عمومي سروې اداره',
        13: 'د ترکیې د دیني چارو ریاست',
        3: 'د اسلامي نړۍ ټولنه',
      },
      _ => const <int, String>{
        1: 'University of Karachi',
        2: 'ISNA',
        4: 'Umm Al-Qura, Makkah',
        5: 'Egyptian General Authority',
        13: 'Diyanet İşleri Başkanlığı',
        3: 'Muslim World League',
      },
    };
    return names[id] ?? names[3]!;
  }

  String _localizedHighLatitudeName(HighLatitudeRule rule, String language) {
    final Map<HighLatitudeRule, String> names = switch (language) {
      'tr' => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'Gecenin yarısı',
        HighLatitudeRule.oneSeventh: 'Gecenin yedide biri',
        HighLatitudeRule.angleBased: 'Açıya dayalı',
      },
      'fr' => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'Milieu de la nuit',
        HighLatitudeRule.oneSeventh: 'Un septième de la nuit',
        HighLatitudeRule.angleBased: 'Selon l’angle',
      },
      'es' => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'Mitad de la noche',
        HighLatitudeRule.oneSeventh: 'Un séptimo de la noche',
        HighLatitudeRule.angleBased: 'Según el ángulo',
      },
      'de' => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'Mitte der Nacht',
        HighLatitudeRule.oneSeventh: 'Ein Siebtel der Nacht',
        HighLatitudeRule.angleBased: 'Winkelbasiert',
      },
      'ar' => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'منتصف الليل',
        HighLatitudeRule.oneSeventh: 'سُبع الليل',
        HighLatitudeRule.angleBased: 'حسب الزاوية',
      },
      'ur' => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'آدھی رات',
        HighLatitudeRule.oneSeventh: 'رات کا ساتواں حصہ',
        HighLatitudeRule.angleBased: 'زاویے کے مطابق',
      },
      'ps' => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'د شپې منځ',
        HighLatitudeRule.oneSeventh: 'د شپې اوومه برخه',
        HighLatitudeRule.angleBased: 'د زاویې له مخې',
      },
      _ => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'Middle of the Night',
        HighLatitudeRule.oneSeventh: 'One Seventh of the Night',
        HighLatitudeRule.angleBased: 'Angle Based',
      },
    };
    return names[rule]!;
  }

  String _localizedAdjustmentsSummary(PrayerSettings settings, AppStrings s) {
    final String summary = PrayerType.values
        .where((PrayerType type) => settings.adjustmentFor(type) != 0)
        .map((PrayerType type) {
          final int adjustment = settings.adjustmentFor(type);
          return '${type.localizedName(s.locale.languageCode)} '
              '${adjustment >= 0 ? '+' : ''}${s.number(adjustment)}';
        })
        .join(' · ');
    return summary.isEmpty ? s.minutes(0) : summary;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

class _SettingsHelpGroup extends StatelessWidget {
  const _SettingsHelpGroup({
    required this.title,
    required this.items,
    this.bottomPadding = 24,
  });

  final String title;
  final List<_SettingsHelpItem> items;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: bottomPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        for (final _SettingsHelpItem item in items) item,
      ],
    ),
  );
}

class _SettingsHelpItem extends StatelessWidget {
  const _SettingsHelpItem({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _DialogExplanation extends StatelessWidget {
  const _DialogExplanation({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
    child: Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _DialogChoice extends StatelessWidget {
  const _DialogChoice({
    required this.selected,
    required this.label,
    this.description,
  });

  final bool selected;
  final String label;
  final String? description;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        size: 20,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label),
            if (description != null) ...<Widget>[
              const SizedBox(height: 3),
              Text(description!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    ],
  );
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });
  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(title)),
            Text(
              valueLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _RadioLikeTile extends StatelessWidget {
  const _RadioLikeTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    leading: Icon(
      selected
          ? Icons.radio_button_checked_rounded
          : Icons.radio_button_unchecked_rounded,
      color: selected ? Theme.of(context).colorScheme.primary : null,
    ),
    onTap: onTap,
  );
}
