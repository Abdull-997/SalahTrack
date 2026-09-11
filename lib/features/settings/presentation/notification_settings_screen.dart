import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/shared/errors/user_error_message.dart';

/// Keeps permission status in the app theme. Operating-system settings are
/// opened only through the explicitly labelled external-settings button.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key}) : isExactAlarm = false;

  const NotificationSettingsScreen.exactAlarms({super.key})
    : isExactAlarm = true;

  final bool isExactAlarm;

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool? _allowed;
  bool _working = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _update();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _update();
  }

  Future<void> _update({
    Future<void> Function(NotificationService service)? action,
  }) async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final NotificationService service = ref.read(notificationServiceProvider);
      await service.initialize();
      if (!mounted) return;
      await action?.call(service);
      final bool allowed = widget.isExactAlarm
          ? await service.canScheduleExactly()
          : await service.notificationsAllowed();
      if (mounted) setState(() => _allowed = allowed);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String permissionKey = widget.isExactAlarm
        ? 'exactAlarmPermission'
        : 'notificationPermission';
    return Scaffold(
      appBar: AppBar(title: Text(s.t(permissionKey))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      widget.isExactAlarm
                          ? Icons.alarm_rounded
                          : _allowed == true
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_rounded,
                      size: 40,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 20),
                    if (_allowed != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          s.t(
                            widget.isExactAlarm
                                ? (_allowed!
                                      ? 'exactAlarmsEnabled'
                                      : 'exactAlarmsDisabled')
                                : (_allowed!
                                      ? 'notificationsEnabled'
                                      : 'notificationsDisabled'),
                          ),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      s.t(
                        widget.isExactAlarm
                            ? 'exactAlarmPermissionHelp'
                            : 'notificationPermissionHelp',
                      ),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    if (_working)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: LinearProgressIndicator(),
                      ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 20),
                      Text(
                        userErrorMessage(context, _error!),
                        style: TextStyle(color: scheme.error),
                      ),
                      TextButton.icon(
                        onPressed: _working ? null : () => _update(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(s.t('retry')),
                      ),
                    ],
                    if (_allowed == false && !widget.isExactAlarm) ...<Widget>[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _working
                            ? null
                            : () => _update(
                                action: (service) async {
                                  await service.requestPermission();
                                },
                              ),
                        icon: const Icon(Icons.notifications_outlined),
                        label: Text(s.t('notificationPermission')),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _working
                  ? null
                  : () => _update(
                      action: (service) => widget.isExactAlarm
                          ? service.openExactAlarmSettings()
                          : service.openNotificationSettings(),
                    ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(s.t('openSystemSettings')),
            ),
            const SizedBox(height: 12),
            Text(
              s.t('systemSettingsAppearance'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
