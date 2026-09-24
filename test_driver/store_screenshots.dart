import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  final String platform = Platform.environment['STORE_PLATFORM'] ?? '';
  final String device = Platform.environment['STORE_DEVICE'] ?? '';
  final String output = Platform.environment['STORE_OUTPUT'] ?? 'store_screenshots';
  if (!<String>{'android', 'ios'}.contains(platform) || device.isEmpty) {
    throw StateError('Set STORE_PLATFORM and STORE_DEVICE before flutter drive.');
  }

  // The test waits for each request, so the host captures the native display
  // before the test navigates to the next screen.
  final ServerSocket server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 48765);
  server.listen((Socket socket) async {
    try {
      final String name = await socket
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 20));
      if (!RegExp(r'^[a-z]{2}/0[1-5]_[a-z]+$').hasMatch(name)) {
        throw StateError('Unexpected screenshot name: $name');
      }
      final File file = File('$output/$name.png');
      await file.parent.create(recursive: true);
      if (platform == 'android') {
        final ProcessResult result = await Process.run(
          'adb',
          <String>['-s', device, 'exec-out', 'screencap', '-p'],
          stdoutEncoding: null,
        );
        if (result.exitCode != 0) {
          throw StateError('Android screenshot failed: ${result.stderr}');
        }
        await file.writeAsBytes(result.stdout as List<int>);
      } else {
        final ProcessResult result = await Process.run('xcrun', <String>[
          'simctl', 'io', device, 'screenshot', '--type=png', file.path,
        ]);
        if (result.exitCode != 0) {
          throw StateError('iOS screenshot failed: ${result.stderr}');
        }
      }
      final List<int> bytes = await file.readAsBytes();
      if (bytes.length < 10000 ||
          bytes[0] != 0x89 ||
          bytes[1] != 0x50 ||
          bytes[2] != 0x4e ||
          bytes[3] != 0x47) {
        throw StateError('Screenshot is empty or is not a PNG: ${file.path}');
      }
      stdout.writeln(file.path);
      socket.write('OK\n');
    } catch (error) {
      stderr.writeln(error);
      socket.write('ERROR\n');
    }
    await socket.flush();
    await socket.close();
  });
  await integrationDriver();
}
