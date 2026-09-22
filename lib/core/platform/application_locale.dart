import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lets Android-owned UI, including the launcher name, follow the OS language.
class ApplicationLocale {
  ApplicationLocale._();

  static const MethodChannel _channel = MethodChannel(
    'salahtrack/system_settings',
  );

  static Future<void> followSystem() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      // An empty locale list clears overrides saved by earlier app versions.
      // Flutter's selected in-app language remains a separate preference.
      await _channel.invokeMethod<void>('setApplicationLocale', '');
    } on MissingPluginException {
      // Older installed builds may not yet provide the locale bridge.
    } on PlatformException {
      // Devices without per-app language support already follow the system.
    }
  }
}
