import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_language.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/shared/errors/user_error_message.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final String selectedCode = ref
        .watch(settingsControllerProvider)
        .localeCode;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('languageSelect'))),
      body: ListView.separated(
        itemCount: appLanguages.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final AppLanguage language = appLanguages[index];
          final bool selected = language.code == selectedCode;
          return ListTile(
            title: Text(language.name),
            subtitle: Text(language.code),
            trailing: Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? Theme.of(context).colorScheme.primary : null,
            ),
            enabled: !_saving,
            onTap: selected ? null : () => _select(language.code),
          );
        },
      ),
    );
  }

  Future<void> _select(String languageCode) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .setLocale(languageCode);
      await ref.read(notificationServiceProvider).initialize();
      final UserLocation? location = ref
          .read(settingsControllerProvider)
          .location;
      if (location != null) {
        final UserLocation localized = await ref
            .read(locationServiceProvider)
            .localizeLocation(location, languageCode: languageCode);
        await ref
            .read(settingsControllerProvider.notifier)
            .setLocation(localized);
      }
      ref.invalidate(todayPrayerDayProvider);
      // Reloading immediately also replaces already scheduled notifications
      // with texts and prayer names from the newly selected language.
      await ref.read(todayPrayerDayProvider.future);
      if (mounted) Navigator.of(context).pop();
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
}
