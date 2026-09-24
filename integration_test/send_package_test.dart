// End-to-end smoke test against the production backend: sign in, post a
// package through the "Send a package" flow, then cancel it from the
// Packages tab so no live order is left behind.
//
// Run on a booted simulator with location pre-granted:
//   xcrun simctl privacy <udid> grant location com.CarryOnApp.App
//   xcrun simctl location <udid> set 33.8938,35.5018
//   flutter test integration_test/send_package_test.dart -d <udid>
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login, send a package, cancel it', (tester) async {
    await app.main();
    await tester.pump();

    // Splash → home. The last tab reads "Login" or "Account".
    await _pumpUntilAny(tester, [_navLabel('Login'), _navLabel('Account')]);

    // ---------------------------------------------------------------- login
    if (_navLabel('Login').evaluate().isNotEmpty) {
      await tester.tap(_navLabel('Login'));
      await _pumpUntil(tester, _fieldWithHint('Email'));
      await tester.enterText(_fieldWithHint('Email'), _email);
      await tester.enterText(_fieldWithHint('Password'), _password);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await _pumpUntil(tester, _navLabel('Account'), timeout: 40);
    }

    // ----------------------------------------------------------- send flow
    await tester.tap(_navLabel('Home'));
    await _pumpUntil(tester, find.text('Send a package'), timeout: 30);
    await _scrollTo(tester, find.text('Send a package'));
    await tester.tap(find.text('Send a package'));
    await _pumpUntil(tester, find.text('Send Package'));

    // Pickup and delivery addresses through the picker (two InkWells in
    // the route card).
    final routeTiles = find.descendant(
      of: find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == 'OrderFormRouteCard',
      ),
      matching: find.byType(InkWell),
    );
    await _pickAddress(tester, routeTiles.at(0), name: 'Test pickup');
    await _pumpUntil(tester, find.text('Send Package'));
    await _pickAddress(tester, routeTiles.at(1), name: 'Test delivery');
    await _pumpUntil(tester, find.text('Send Package'));

    // Receiver details.
    await _scrollTo(tester, _fieldWithHint('Receiver Name'));
    await tester.enterText(_fieldWithHint('Receiver Name'), 'Flutter Test');
    await tester.enterText(_fieldWithHint('Receiver Phone'), '70000000');
    await tester.pump();

    // Step 1 → step 2 ("What & how").
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await _pumpUntil(tester, find.text('Package Type'));

    // Package: first category, value $120 typed, weight 0.5 kg quick pick.
    await _pumpUntil(tester, find.text('Document'), timeout: 30);
    await _scrollTo(tester, find.text('Document'));
    await tester.tap(find.text('Document'));
    await tester.pump();
    await _scrollTo(tester, _fieldWithHint('Package value'));
    await tester.enterText(_fieldWithHint('Package value'), '120');
    await tester.pump();
    await _scrollTo(tester, find.text('0.5 kg'));
    await tester.tap(find.text('0.5 kg'));
    await tester.pump();

    // Reward $10 (delivery stays "Needed Soon", payment stays cash).
    await _scrollTo(tester, find.text(r'$10'));
    await tester.tap(find.text(r'$10'));
    await tester.pump();

    // Submit.
    await tester.tap(find.widgetWithText(FilledButton, 'Create Package'));
    await _pumpUntil(tester, find.text('All Done'), timeout: 60);
    await tester.tap(find.text('Continue'));

    // --------------------------------------------------------- cancel it
    await _pumpUntil(tester, find.textContaining('Tracking #'), timeout: 40);
    final trackingText = tester
        .widget<Text>(find.textContaining('Tracking #').first)
        .data;
    // ignore: avoid_print
    print('CREATED $trackingText');
    await tester.tap(find.textContaining('Tracking #').first);
    await _pumpUntil(tester, find.text('Review Package'));
    await _scrollTo(tester, find.text('Cancel Package'));
    await tester.tap(find.text('Cancel Package'));
    await _pumpUntil(tester, find.text('Yes'));
    await tester.tap(find.text('Yes'));
    await _pumpUntil(tester, find.textContaining('Tracking #'), timeout: 40);
    await _pumpUntil(tester, find.textContaining('Cancelled'), timeout: 30);
    // ignore: avoid_print
    print('CANCELLED $trackingText');
  });
}

Finder _navLabel(String label) => find.descendant(
  of: find.byType(GlassNavigationBar),
  matching: find.text(label),
);

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Future<void> _pickAddress(
  WidgetTester tester,
  Finder tile, {
  required String name,
}) async {
  await _scrollTo(tester, tile);
  await tester.tap(tile);
  // New address: the picker locates and opens on the form (saved
  // addresses first, map preview, fields).
  await _pumpUntil(tester, _fieldWithHint('Address Name'), timeout: 40);
  await _scrollTo(tester, _fieldWithHint('Address Name'));
  await tester.enterText(_fieldWithHint('Address Name'), name);
  await tester.enterText(_fieldWithHint('Street'), 'Hamra Street');
  await tester.enterText(_fieldWithHint('Building'), 'Test building');
  await tester.enterText(_fieldWithHint('Apartment'), '1');
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump(const Duration(milliseconds: 300));
}

/// Pumps frames until any of [finders] matches.
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

/// Pumps frames until [finder] matches or [timeout] seconds elapse.
/// `pumpAndSettle` is unusable here: the home carousel keeps a timer.
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
