import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_language.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/location/location_suggestions.dart';
import 'package:salah_focus/core/time/timezone_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/friday_prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_settings.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/presentation/language_selection_screen.dart';
import 'package:salah_focus/features/settings/presentation/notification_settings_screen.dart';
import 'package:salah_focus/features/settings/presentation/privacy_legal_screen.dart';
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
      appBar: AppBar(title: Text(s.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          _SectionTitle(
            title: s.t('prayerTimes'),
            icon: Icons.schedule_rounded,
            infoKey: 'settings-info-prayer-times',
            infoTooltip: s.t('settingsInfo'),
            onInfo: () => _showCategoryInfo(
              title: s.t('prayerTimes'),
              items: _prayerTimesHelpItems(s),
            ),
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
                const Divider(height: 1),
                SwitchListTile(
                  key: const ValueKey<String>('friday-prayer-enabled'),
                  secondary: const Icon(Icons.mosque_outlined),
                  title: Text(s.t('fridayPrayer')),
                  subtitle: Text(_fridayPrayerTime(s, settings.fridayPrayer)),
                  value: settings.fridayPrayer.enabled,
                  onChanged: _working
                      ? null
                      : (bool enabled) => _savePrayerSettings(
                          settings.copyWith(
                            fridayPrayer: settings.fridayPrayer.copyWith(
                              enabled: enabled,
                            ),
                          ),
                        ),
                ),
                if (settings.fridayPrayer.enabled) ...<Widget>[
                  const Divider(height: 1),
                  ListTile(
                    key: const ValueKey<String>('friday-prayer-time'),
                    leading: const Icon(Icons.access_time_rounded),
                    title: Text(s.t('fridayPrayerTime')),
                    subtitle: Text(_fridayPrayerTime(s, settings.fridayPrayer)),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: _working
                        ? null
                        : () => _chooseFridayPrayerTime(settings),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: s.t('permissions'),
            icon: Icons.notifications_active_outlined,
            infoKey: 'settings-info-permissions',
            infoTooltip: s.t('settingsInfo'),
            onInfo: () => _showCategoryInfo(
              title: s.t('permissions'),
              items: _permissionsHelpItems(s),
            ),
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
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: s.t('prayerReminders'),
            icon: Icons.notifications_active_outlined,
            infoKey: 'settings-info-reminders',
            infoTooltip: s.t('settingsInfo'),
            onInfo: () => _showCategoryInfo(
              title: s.t('prayerReminders'),
              items: _reminderHelpItems(s),
            ),
          ),
          Card(
            child: Column(
              children: <Widget>[
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
            title: s.t('ramadan'),
            icon: Icons.nights_stay_outlined,
            infoKey: 'settings-info-ramadan',
            infoTooltip: s.t('settingsInfo'),
            onInfo: () => _showCategoryInfo(
              title: s.t('ramadan'),
              items: _ramadanHelpItems(s),
            ),
          ),
          Card(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  key: const ValueKey<String>('ramadan-features-enabled'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: Text(s.t('ramadanFeatures')),
                  subtitle: Text(
                    prefs.ramadanSettings.enabled
                        ? s.t('ramadanFeaturesOutsideStatus')
                        : s.t('ramadanHistoryPreserved'),
                  ),
                  value: prefs.ramadanSettings.enabled,
                  onChanged: (bool value) => _saveRamadanSettings(
                    prefs.ramadanSettings.copyWith(enabled: value),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  key: const ValueKey<String>('suhur-reminder-enabled'),
                  secondary: const Icon(Icons.free_breakfast_outlined),
                  title: Text(s.t('suhurReminder')),
                  subtitle: Text(
                    s.t(
                      'minutesBefore',
                      params: <String, String>{
                        'minutes': s.number(
                          prefs.ramadanSettings.suhurReminderMinutes,
                        ),
                      },
                    ),
                  ),
                  value: prefs.ramadanSettings.suhurReminderEnabled,
                  onChanged: prefs.ramadanSettings.enabled
                      ? (bool value) => _saveRamadanSettings(
                          prefs.ramadanSettings.copyWith(
                            suhurReminderEnabled: value,
                          ),
                        )
                      : null,
                ),
                if (prefs.ramadanSettings.enabled &&
                    prefs.ramadanSettings.suhurReminderEnabled) ...<Widget>[
                  ListTile(
                    key: const ValueKey<String>('suhur-reminder-time'),
                    contentPadding: const EdgeInsetsDirectional.only(
                      start: 72,
                      end: 16,
                    ),
                    title: Text(s.t('reminderTime')),
                    subtitle: Text(
                      s.t(
                        'minutesBefore',
                        params: <String, String>{
                          'minutes': s.number(
                            prefs.ramadanSettings.suhurReminderMinutes,
                          ),
                        },
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _chooseRamadanReminderMinutes(
                      prefs.ramadanSettings,
                      suhur: true,
                    ),
                  ),
                ],
                const Divider(height: 1),
                SwitchListTile(
                  key: const ValueKey<String>('iftar-reminder-enabled'),
                  secondary: const Icon(Icons.wb_twilight_outlined),
                  title: Text(s.t('iftarReminder')),
                  subtitle: Text(
                    s.t(
                      'minutesBefore',
                      params: <String, String>{
                        'minutes': s.number(
                          prefs.ramadanSettings.iftarReminderMinutes,
                        ),
                      },
                    ),
                  ),
                  value: prefs.ramadanSettings.iftarReminderEnabled,
                  onChanged: prefs.ramadanSettings.enabled
                      ? (bool value) => _saveRamadanSettings(
                          prefs.ramadanSettings.copyWith(
                            iftarReminderEnabled: value,
                          ),
                        )
                      : null,
                ),
                if (prefs.ramadanSettings.enabled &&
                    prefs.ramadanSettings.iftarReminderEnabled) ...<Widget>[
                  ListTile(
                    key: const ValueKey<String>('iftar-reminder-time'),
                    contentPadding: const EdgeInsetsDirectional.only(
                      start: 72,
                      end: 16,
                    ),
                    title: Text(s.t('reminderTime')),
                    subtitle: Text(
                      s.t(
                        'minutesBefore',
                        params: <String, String>{
                          'minutes': s.number(
                            prefs.ramadanSettings.iftarReminderMinutes,
                          ),
                        },
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _chooseRamadanReminderMinutes(
                      prefs.ramadanSettings,
                      suhur: false,
                    ),
                  ),
                ],
                const Divider(height: 1),
                SwitchListTile(
                  key: const ValueKey<String>('tarawih-tracking-enabled'),
                  secondary: const Icon(Icons.mosque_outlined),
                  title: Text(s.t('tarawihTracking')),
                  value: prefs.ramadanSettings.tarawihTrackingEnabled,
                  onChanged: prefs.ramadanSettings.enabled
                      ? (bool value) => _saveRamadanSettings(
                          prefs.ramadanSettings.copyWith(
                            tarawihTrackingEnabled: value,
                          ),
                        )
                      : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  key: const ValueKey<String>('qiyam-tracking-enabled'),
                  secondary: const Icon(Icons.bedtime_outlined),
                  title: Text(s.t('qiyamTracking')),
                  value: prefs.ramadanSettings.qiyamTrackingEnabled,
                  onChanged: prefs.ramadanSettings.enabled
                      ? (bool value) => _saveRamadanSettings(
                          prefs.ramadanSettings.copyWith(
                            qiyamTrackingEnabled: value,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: s.t('confirmationText'),
            icon: Icons.check_circle_outline_rounded,
            infoKey: 'settings-info-confirmation',
            infoTooltip: s.t('settingsInfo'),
            onInfo: () => _showCategoryInfo(
              title: s.t('confirmationText'),
              items: <Widget>[
                _SettingsHelpParagraph(text: s.t('confirmationTextHelp')),
              ],
            ),
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
          _SectionTitle(
            title: s.t('theme'),
            icon: Icons.palette_outlined,
            infoKey: 'settings-info-theme',
            infoTooltip: s.t('settingsInfo'),
            onInfo: () => _showCategoryInfo(
              title: s.t('theme'),
              items: _themeHelpItems(s),
            ),
          ),
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
          _SectionTitle(
            title: s.t('language'),
            icon: Icons.language_rounded,
            infoKey: 'settings-info-language',
            infoTooltip: s.t('settingsInfo'),
            onInfo: () => _showCategoryInfo(
              title: s.t('language'),
              items: <_SettingsHelpItem>[
                _SettingsHelpItem(
                  title: s.t('languageSelect'),
                  description: s.t('languageHelp'),
                ),
              ],
            ),
          ),
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
          const SizedBox(height: 18),
          _SectionTitle(
            title: s.t('privacyLegal'),
            icon: Icons.shield_outlined,
            infoKey: 'settings-info-privacy-legal',
            infoTooltip: s.t('settingsInfo'),
            onInfo: () => _showCategoryInfo(
              title: s.t('privacyLegal'),
              items: <Widget>[
                _SettingsHelpParagraph(text: s.t('privacyLegalHelp')),
              ],
            ),
          ),
          Card(
            child: ListTile(
              key: const ValueKey<String>('privacy-legal-settings-tile'),
              leading: const Icon(Icons.policy_outlined),
              title: Text(s.t('privacyLegal')),
              subtitle: Text(s.t('privacyLegalHelp')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyLegalScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_SettingsHelpItem> _prayerTimesHelpItems(AppStrings s) {
    final String language = s.locale.languageCode;
    return <_SettingsHelpItem>[
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
      _SettingsHelpItem(
        title: s.t('fridayPrayer'),
        description: s.t('fridayPrayerHelp'),
      ),
    ];
  }

  List<_SettingsHelpItem> _permissionsHelpItems(AppStrings s) =>
      <_SettingsHelpItem>[
        _SettingsHelpItem(
          title: s.t('notificationPermission'),
          description: s.t('notificationPermissionHelp'),
        ),
        _SettingsHelpItem(
          title: s.t('exactAlarmPermission'),
          description: s.t('exactAlarmPermissionHelp'),
        ),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          _SettingsHelpItem(
            title: s.t('fullScreenAlarmPermission'),
            description: s.t('fullScreenAlarmPermissionHelp'),
          ),
      ];

  List<_SettingsHelpItem> _reminderHelpItems(AppStrings s) =>
      <_SettingsHelpItem>[
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
      ];

  List<_SettingsHelpItem> _themeHelpItems(AppStrings s) => <_SettingsHelpItem>[
    _SettingsHelpItem(
      title: s.t('system'),
      description: s.t('systemThemeHelp'),
    ),
    _SettingsHelpItem(title: s.t('light'), description: s.t('lightThemeHelp')),
    _SettingsHelpItem(title: s.t('dark'), description: s.t('darkThemeHelp')),
  ];

  List<Widget> _ramadanHelpItems(AppStrings s) => <Widget>[
    _SettingsHelpParagraph(text: s.t('ramadanFeaturesHelp')),
    _SettingsHelpItem(
      title: s.t('ramadanFeatures'),
      description: s.t('ramadanMasterSwitchHelp'),
    ),
    _SettingsHelpItem(title: s.t('suhur'), description: s.t('suhurHelp')),
    _SettingsHelpItem(title: s.t('iftar'), description: s.t('iftarHelp')),
    _SettingsHelpItem(
      title: s.t('fasting'),
      description: s.t('fastingTrackerHelp'),
    ),
    _SettingsHelpItem(title: s.t('tarawih'), description: s.t('tarawihHelp')),
    _SettingsHelpItem(title: s.t('qiyam'), description: s.t('qiyamHelp')),
    _SettingsHelpItem(
      title: s.t('ramadanGoals'),
      description: s.t('ramadanGoalsHelp'),
    ),
    _SettingsHelpParagraph(text: s.t('ramadanHistoryPreserved')),
  ];

  Future<void> _showCategoryInfo({
    required String title,
    required List<Widget> items,
  }) => showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      final AppStrings dialogStrings = AppStrings.of(dialogContext);
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items,
            ),
          ),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogStrings.t('close')),
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

  Future<void> _chooseFridayPrayerTime(PrayerSettings current) async {
    final FridayPrayerSettings fridayPrayer = current.fridayPrayer;
    final AppStrings s = AppStrings.of(context);
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: fridayPrayer.hour,
        minute: fridayPrayer.minute,
      ),
      helpText: s.t('fridayPrayerTime'),
      cancelText: s.t('cancel'),
      confirmText: s.t('save'),
    );
    if (selected == null) return;
    await _savePrayerSettings(
      current.copyWith(
        fridayPrayer: fridayPrayer.copyWith(
          minutesFromMidnight: selected.hour * 60 + selected.minute,
        ),
      ),
    );
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
                Consumer(
                  builder: (BuildContext context, WidgetRef dialogRef, _) {
                    final PrayerDay? day = dialogRef
                        .watch(todayPrayerDayProvider)
                        .when(
                          data: (PrayerDay? value) => value,
                          error: (_, _) => null,
                          loading: () => null,
                        );
                    final Map<PrayerType, PrayerEntry> entries =
                        <PrayerType, PrayerEntry>{
                          for (final PrayerEntry entry
                              in day?.entries ?? const <PrayerEntry>[])
                            entry.type: entry,
                        };
                    final bool hasAllPrayerTimes = PrayerType.values.every(
                      entries.containsKey,
                    );
                    final AppStrings strings = AppStrings.of(context);
                    return AlertDialog(
                      insetPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 24,
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
                      title: Text(strings.t('manualAdjustments')),
                      content: SizedBox(
                        width: 420,
                        child: ListView(
                          shrinkWrap: true,
                          children: <Widget>[
                            Text(strings.t('minuteAdjustmentsHelp')),
                            if (!hasAllPrayerTimes) ...<Widget>[
                              const SizedBox(height: 14),
                              _PrayerTimeUnavailableNotice(
                                text: strings.t('noData'),
                              ),
                            ],
                            const SizedBox(height: 16),
                            for (final PrayerType type in PrayerType.values)
                              _AdjustmentPrayerRow(
                                type: type,
                                time: _adjustmentPreviewTime(
                                  strings,
                                  entries[type],
                                  values[type] ?? 0,
                                ),
                                adjustment: strings.minutes(values[type] ?? 0),
                                onDecrease: (values[type] ?? 0) <= -60
                                    ? null
                                    : () => setDialogState(
                                        () => values[type] =
                                            (values[type] ?? 0) - 1,
                                      ),
                                onIncrease: (values[type] ?? 0) >= 60
                                    ? null
                                    : () => setDialogState(
                                        () => values[type] =
                                            (values[type] ?? 0) + 1,
                                      ),
                              ),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(strings.t('cancel')),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(strings.t('save')),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ) ??
        false;
    if (accepted) {
      await _savePrayerSettings(current.copyWith(adjustments: values));
    }
  }

  String _adjustmentPreviewTime(
    AppStrings strings,
    PrayerEntry? entry,
    int adjustment,
  ) {
    if (entry == null) return '—';
    final DateTime previewUtc = entry.scheduledAtUtc.add(
      Duration(minutes: adjustment - entry.manualOffsetMinutes),
    );
    return strings.time(TimezoneService.toLocal(previewUtc, entry.timezoneId));
  }

  String _fridayPrayerTime(AppStrings strings, FridayPrayerSettings settings) =>
      strings.time(DateTime(2000, 1, 1, settings.hour, settings.minute));

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
    if (mounted) {
      await _syncFridayPrayerReminders();
      await _syncRamadanReminders();
      ref.invalidate(todayPrayerDayProvider);
    }
  }

  Future<void> _requestExactAlarms() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationSettingsScreen.exactAlarms(),
      ),
    );
    if (mounted) {
      await _syncFridayPrayerReminders();
      await _syncRamadanReminders();
      ref.invalidate(todayPrayerDayProvider);
    }
  }

  Future<void> _requestFullScreenAlarms() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationSettingsScreen.fullScreenAlarms(),
      ),
    );
    if (mounted) ref.invalidate(todayPrayerDayProvider);
  }

  Future<void> _saveRamadanSettings(RamadanSettings settings) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setRamadanSettings(settings);
  }

  Future<void> _chooseRamadanReminderMinutes(
    RamadanSettings current, {
    required bool suhur,
  }) async {
    final AppStrings s = AppStrings.of(context);
    final int? value = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) => SimpleDialog(
        title: Text(s.t('reminderTime')),
        children: <Widget>[
          for (final int minutes in <int>[15, 30, 45, 60])
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(minutes),
              child: _DialogChoice(
                selected:
                    minutes ==
                    (suhur
                        ? current.suhurReminderMinutes
                        : current.iftarReminderMinutes),
                label: s.t(
                  'minutesBefore',
                  params: <String, String>{'minutes': s.number(minutes)},
                ),
              ),
            ),
        ],
      ),
    );
    if (value == null) return;
    await _saveRamadanSettings(
      suhur
          ? current.copyWith(suhurReminderMinutes: value)
          : current.copyWith(iftarReminderMinutes: value),
    );
  }

  Future<void> _savePrayerSettings(PrayerSettings settings) async {
    final FridayPrayerSettings previous = ref
        .read(settingsControllerProvider)
        .prayerSettings
        .fridayPrayer;
    await ref
        .read(settingsControllerProvider.notifier)
        .setPrayerSettings(settings);
    if (settings.fridayPrayer != previous) {
      await _syncFridayPrayerReminders();
    }
    ref.invalidate(todayPrayerDayProvider);
  }

  Future<void> _syncFridayPrayerReminders() async {
    final preferences = ref.read(settingsControllerProvider);
    try {
      await ref
          .read(fridayPrayerReminderPlannerProvider)
          .reschedule(
            preferences.prayerSettings.fridayPrayer,
            timezoneId:
                preferences.location?.timezoneId ??
                ref.read(deviceTimezoneIdProvider),
            languageCode: preferences.localeCode,
            nowUtc: ref.read(clockServiceProvider).nowUtc(),
          );
    } on Object {
      // Saving remains available even if the operating system rejects alarms.
    }
  }

  Future<void> _syncRamadanReminders() async {
    final preferences = ref.read(settingsControllerProvider);
    PrayerDay? today;
    try {
      today = preferences.ramadanSettings.enabled
          ? await ref.read(todayPrayerDayProvider.future)
          : null;
      await ref
          .read(ramadanReminderCoordinatorProvider)
          .reschedule(
            today,
            preferences.ramadanSettings,
            nowUtc: ref.read(clockServiceProvider).nowUtc(),
            languageCode: preferences.localeCode,
          );
    } on Object {
      // Saving and permission changes remain available if scheduling fails.
    }
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
      'id' => const <int, String>{
        1: 'Universitas Karachi',
        2: 'Masyarakat Islam Amerika Utara',
        3: 'Liga Muslim Dunia',
        4: 'Universitas Umm Al-Qura, Makkah',
        5: 'Otoritas Umum Survei Mesir',
        13: 'Kepresidenan Urusan Agama Turki',
      },
      'bn' => const <int, String>{
        1: 'করাচি বিশ্ববিদ্যালয়',
        2: 'উত্তর আমেরিকার ইসলামিক সোসাইটি',
        3: 'মুসলিম বিশ্ব লীগ',
        4: 'উম্ম আল-কুরা বিশ্ববিদ্যালয়, মক্কা',
        5: 'মিশরীয় সাধারণ জরিপ কর্তৃপক্ষ',
        13: 'তুরস্কের ধর্মবিষয়ক অধিদপ্তর',
      },
      'pa' => const <int, String>{
        1: 'کراچی یونیورسٹی',
        2: 'شمالی امریکا دی اسلامی سوسائٹی',
        3: 'مسلم ورلڈ لیگ',
        4: 'ام القریٰ یونیورسٹی، مکہ',
        5: 'مصر دی عمومی سروے اتھارٹی',
        13: 'ترکی دے مذہبی معاملیاں دی صدارت',
      },
      'fa' => const <int, String>{
        1: 'دانشگاه کراچی',
        2: 'جامعهٔ اسلامی آمریکای شمالی',
        3: 'اتحادیهٔ جهانی مسلمانان',
        4: 'دانشگاه ام‌القری، مکه',
        5: 'سازمان کل نقشه‌برداری مصر',
        13: 'ریاست امور دینی ترکیه',
      },
      'ms' => const <int, String>{
        1: 'Universiti Karachi',
        2: 'Persatuan Islam Amerika Utara',
        3: 'Liga Muslim Sedunia',
        4: 'Universiti Umm al-Qura, Makkah',
        5: 'Pihak Berkuasa Ukur Am Mesir',
        13: 'Presidensi Hal Ehwal Agama Turkiye',
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
      'id' => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'Tengah malam',
        HighLatitudeRule.oneSeventh: 'Sepertujuh malam',
        HighLatitudeRule.angleBased: 'Berdasarkan sudut',
      },
      'bn' => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'মধ্যরাত',
        HighLatitudeRule.oneSeventh: 'রাতের এক-সপ্তমাংশ',
        HighLatitudeRule.angleBased: 'কোণভিত্তিক',
      },
      'pa' => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'ادھی رات',
        HighLatitudeRule.oneSeventh: 'رات دا ستواں حصہ',
        HighLatitudeRule.angleBased: 'زاویے دے مطابق',
      },
      'fa' => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'نیمه‌شب',
        HighLatitudeRule.oneSeventh: 'یک‌هفتم شب',
        HighLatitudeRule.angleBased: 'بر اساس زاویه',
      },
      'ms' => const <HighLatitudeRule, String>{
        HighLatitudeRule.middleOfNight: 'Pertengahan malam',
        HighLatitudeRule.oneSeventh: 'Satu pertujuh malam',
        HighLatitudeRule.angleBased: 'Berdasarkan sudut',
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
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.infoKey,
    required this.infoTooltip,
    required this.onInfo,
  });

  final String title;
  final IconData icon;
  final String infoKey;
  final String infoTooltip;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
          key: ValueKey<String>(infoKey),
          tooltip: infoTooltip,
          onPressed: onInfo,
          icon: const Icon(Icons.info_outline_rounded),
        ),
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

class _SettingsHelpParagraph extends StatelessWidget {
  const _SettingsHelpParagraph({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _PrayerTimeUnavailableNotice extends StatelessWidget {
  const _PrayerTimeUnavailableNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.schedule_outlined, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class _AdjustmentPrayerRow extends StatelessWidget {
  const _AdjustmentPrayerRow({
    required this.type,
    required this.time,
    required this.adjustment,
    required this.onDecrease,
    required this.onIncrease,
  });

  final PrayerType type;
  final String time;
  final String adjustment;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey<String>('adjustment-row-${type.name}'),
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  type.localizedName(
                    Localizations.localeOf(context).languageCode,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    time,
                    key: ValueKey<String>('adjustment-time-${type.name}'),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: ValueKey<String>('adjustment-minus-${type.name}'),
          onPressed: onDecrease,
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(
          width: 56,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              adjustment,
              key: ValueKey<String>('adjustment-value-${type.name}'),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        IconButton(
          key: ValueKey<String>('adjustment-plus-${type.name}'),
          onPressed: onIncrease,
          icon: const Icon(Icons.add_rounded),
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
