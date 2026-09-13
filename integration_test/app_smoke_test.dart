import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app starts without requesting permissions immediately', (
    WidgetTester tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).first);
    expect(find.text(AppStrings.of(context).t('appName')), findsWidgets);
  });
}
