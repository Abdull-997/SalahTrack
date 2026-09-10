import 'dart:io';

import 'package:flutter/services.dart';

/// Aligns Android's per-app locale with the locale selected inside Salaty.
/// This controls Android-owned UI, such as the launcher label, where supported.
class ApplicationLocale {
  ApplicationLocale._();

  static const MethodChannel _channel = MethodChannel(
    'salah_focus/system_settings',
  );

  static Future<void> apply(String languageCode) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setApplicationLocale', languageCode);
    } on PlatformException {
      // The Flutter locale remains authoritative when a platform does not
      // provide per-app language support.
    }
  }
}
