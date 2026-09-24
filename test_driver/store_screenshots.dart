import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  final String output =
      Platform.environment['STORE_OUTPUT'] ?? 'store_screenshots';
  final String locale = Platform.environment['STORE_LOCALE'] ?? '';
  if (locale.isEmpty) {
    throw StateError('Set STORE_LOCALE before flutter drive.');
  }

  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      if (!RegExp(r'^[a-z]{2}/0[1-5]_[a-z]+$').hasMatch(name) ||
          !name.startsWith('$locale/')) {
        throw StateError('Unexpected screenshot name: $name');
      }
      if (bytes.length < 10000 ||
          bytes[0] != 0x89 ||
          bytes[1] != 0x50 ||
          bytes[2] != 0x4e ||
          bytes[3] != 0x47) {
        throw StateError('Screenshot is empty or is not a PNG: $name');
      }
      final File file = File('$output/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      stdout.writeln('  Saved ${file.path} (${bytes.length} bytes)');
      return true;
    },
  );
}
