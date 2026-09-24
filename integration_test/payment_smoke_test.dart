// Walks the card-payment screens for one role and screenshots them.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/payment_smoke_test.dart -d <udid> \
//     --dart-define=CARRYON_ROLE=sender|carrier \
//     --dart-define=CARRYON_EMAIL=... --dart-define=CARRYON_PASSWORD=... \
//     --dart-define=CARRYON_ORDER_ID=<unpaid card order id> \
//     --dart-define=CARRYON_DISABLE_PUSH=true   (no permission alert)
//
// Sender: My Packages → the unpaid order → Pay now (the backend has no
// Stripe keys locally, so the toast reports card payment unavailable).
// Carrier: Carried Packages → the same order → the "awaiting payment" view.
import 'package:carryon/main.dart' as app;
import 'package:carryon/src/presentation/core/widgets/glass_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _role = String.fromEnvironment('CARRYON_ROLE', defaultValue: 'sender');
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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('card payment screens ($_role)', (tester) async {
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
    if (_role == 'carrier') {
      await tester.tap(find.text('Carried Packages').first);
      await _settle(tester, 4);
    }
    await binding.takeScreenshot('pay_${_role}_01_list');

    final tile = find.text('Tracking #$_orderId');
    await _pumpUntil(tester, tile, timeout: 20);
    await tester.tap(tile.first);
    await _settle(tester, 3);
    // The payment card sits below the fold; scroll the detail list until
    // it is built and visible.
    await tester.scrollUntilVisible(
      find.text('Payment method'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await _settle(tester, 1);
    await binding.takeScreenshot('pay_${_role}_02_detail');

    if (_role == 'sender') {
      await tester.tap(find.widgetWithText(FilledButton, 'Pay now').last);
      await _settle(tester, 4);
      await binding.takeScreenshot('pay_${_role}_03_pay_now');
      expect(find.textContaining('unavailable'), findsWidgets);
    } else {
      await tester.tap(find.widgetWithText(FilledButton, 'Awaiting payment'));
      await _settle(tester, 2);
      await binding.takeScreenshot('pay_${_role}_03_pickup_blocked');
      expect(find.textContaining('has not paid'), findsWidgets);
    }
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
