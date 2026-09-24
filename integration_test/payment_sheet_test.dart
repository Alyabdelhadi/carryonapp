// Opens the real Stripe payment sheet for an accepted card order and leaves
// it on screen for a few seconds (the sheet is native, so capture it with
// `xcrun simctl io <udid> screenshot` while this runs). Needs Stripe test
// keys on the backend.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/payment_sheet_test.dart -d <udid> \
//     --dart-define=CARRYON_ORDER_ID=<order> --dart-define=CARRYON_DISABLE_PUSH=true
import 'package:carryon/main.dart' as app;
import 'package:carryon/src/presentation/core/widgets/glass_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _email = String.fromEnvironment(
  'CARRYON_EMAIL',
  defaultValue: 'infinite1flight@gmail.com',
);
const _password = String.fromEnvironment(
  'CARRYON_PASSWORD',
  defaultValue: 'test12345',
);
const _orderId = String.fromEnvironment('CARRYON_ORDER_ID', defaultValue: '');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open the Stripe sheet', (tester) async {
    await app.main();
    await tester.pump();
    await _pumpUntilAny(tester, [_navLabel('Login'), _navLabel('Account')]);
    if (_navLabel('Login').evaluate().isNotEmpty) {
      await tester.tap(_navLabel('Login'));
      await _pumpUntil(tester, _fieldWithHint('Email'));
      await tester.enterText(_fieldWithHint('Email'), _email);
      await tester.enterText(_fieldWithHint('Password'), _password);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await _pumpUntil(tester, _navLabel('Account'), timeout: 40);
    }
    await tester.tap(_navLabel('Packages'));
    await _settle(tester, 4);
    final tile = find.text('Tracking #$_orderId');
    await _pumpUntil(tester, tile, timeout: 20);
    await tester.tap(tile.first);
    await _settle(tester, 3);
    await tester.tap(find.widgetWithText(FilledButton, 'Pay now').last);
    // The native sheet takes over; keep pumping so it stays open.
    await _settle(tester, 25);
  });
}

Finder _navLabel(String label) => find.descendant(
  of: find.byType(GlassNavigationBar),
  matching: find.text(label),
);

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Future<void> _settle(WidgetTester tester, int seconds) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _pumpUntilAny(
  WidgetTester tester,
  List<Finder> finders, {
  int timeout = 20,
}) async {
  final deadline = DateTime.now().add(Duration(seconds: timeout));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finders.any((f) => f.evaluate().isNotEmpty)) return;
  }
  throw TestFailure('Timed out waiting for any of $finders');
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int timeout = 20,
}) async {
  final deadline = DateTime.now().add(Duration(seconds: timeout));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}
