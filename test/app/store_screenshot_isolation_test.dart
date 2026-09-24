import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/core/time/clock_service.dart';
import 'package:salah_focus/features/qibla/presentation/qibla_screen.dart';

void main() {
  test('production providers do not enable store demo inputs', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(storeScreenshotModeProvider), isFalse);
    expect(container.read(qiblaScreenshotHeadingProvider), isNull);
    expect(container.read(clockServiceProvider), isA<SystemClockService>());
  });
}
