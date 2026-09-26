// Device check for the order form's weight and custom reward rules: a 0
// weight and a 0 "Other" reward are refused, a typed reward is accepted
// without an "Add" button. Stops before "Create Package" so no order is
// created. Prints `SHOT <name>` and holds the frame so a watcher can take
// simulator screenshots.
//
//   flutter test integration_test/order_form_amounts_test.dart -d <udid>
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

  testWidgets('weight and Other reward must be above 0', (tester) async {
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

    await tester.tap(_navLabel('Home'));
    await _pumpUntil(tester, find.text('Send a package'), timeout: 30);
    await _scrollTo(tester, find.text('Send a package'));
    await tester.tap(find.text('Send a package'));
    await _pumpUntil(tester, find.text('Send Package'));

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

    await _scrollTo(tester, _fieldWithHint('Receiver Name'));
    await tester.enterText(_fieldWithHint('Receiver Name'), 'Flutter Test');
    await tester.enterText(_fieldWithHint('Receiver Phone'), '70000000');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await _pumpUntil(tester, find.text('Package Type'));

    await _pumpUntil(tester, find.text('Document'), timeout: 30);
    await _scrollTo(tester, find.text('Document'));
    await tester.tap(find.text('Document'));
    await tester.pump();
    await _scrollTo(tester, _fieldWithHint('Package value'));
    await tester.enterText(_fieldWithHint('Package value'), '120');

    // Weight 0 → refused.
    await _scrollTo(tester, _fieldWithHint('Weight'));
    await tester.enterText(_fieldWithHint('Weight'), '0');
    await tester.pump();
    await _scrollTo(tester, find.text(r'$10'));
    await tester.tap(find.text(r'$10'));
    await tester.pump();
    await _submit(tester);
    await _pumpUntil(tester, find.text('Enter a weight greater than 0.'));
    await _shot(tester, 'weight_zero');
    await _pumpUntilGone(tester, find.text('Enter a weight greater than 0.'));

    // Valid weight; reward "Other" shows a box with the keyboard up.
    await _scrollTo(tester, _fieldWithHint('Weight'));
    await tester.enterText(_fieldWithHint('Weight'), '2');
    await tester.pump();
    await _scrollTo(tester, find.text('Other'));
    await tester.tap(find.text('Other'));
    await _pumpUntil(tester, _fieldWithHint('Enter Reward Amount'));
    expect(find.text('Add Reward'), findsNothing);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TextField>()
          ?.decoration
          ?.hintText,
      'Enter Reward Amount',
    );
    await _shot(tester, 'other_open');

    // Other = 0 → refused.
    await tester.enterText(_fieldWithHint('Enter Reward Amount'), '0');
    await tester.pump();
    await _submit(tester);
    await _pumpUntil(tester, find.text('Enter a reward greater than 0.'));
    await _shot(tester, 'reward_zero');
    await _pumpUntilGone(tester, find.text('Enter a reward greater than 0.'));

    // Letters are filtered out; a typed 15 is taken without "Add".
    await tester.enterText(_fieldWithHint('Enter Reward Amount'), '');
    await tester.pump();
    await tester.enterText(_fieldWithHint('Enter Reward Amount'), 'ab');
    await tester.pump();
    expect(
      tester
          .widget<TextField>(_fieldWithHint('Enter Reward Amount'))
          .controller!
          .text,
      isEmpty,
    );
    await tester.enterText(_fieldWithHint('Enter Reward Amount'), '15');
    await tester.pump();
    // The overview card mirrors the reward once it is accepted.
    await _pumpUntil(tester, find.textContaining('15'));

    // Tap on empty space closes the keyboard.
    await tester.tapAt(const Offset(8, 200));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      FocusManager.instance.primaryFocus is FocusScopeNode ||
          FocusManager.instance.primaryFocus == null,
      isTrue,
    );
    await _shot(tester, 'reward_15');
    // ignore: avoid_print
    print('RESULT ok');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Future<void> _submit(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Create Package');
  await _scrollTo(tester, button);
  await tester.tap(button);
  await tester.pump();
}

Future<void> _shot(WidgetTester tester, String name) async {
  // ignore: avoid_print
  print('SHOT $name');
  final end = DateTime.now().add(const Duration(seconds: 4));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline) && finder.evaluate().isNotEmpty) {
    await tester.pump(const Duration(milliseconds: 250));
  }
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
  // The form is a lazy list: a field scrolled far off is not built, so
  // look below first, then above.
  final scrollable = find.byType(Scrollable).first;
  for (final delta in [120.0, -120.0]) {
    if (finder.evaluate().isNotEmpty) break;
    try {
      await tester.scrollUntilVisible(
        finder,
        delta,
        scrollable: scrollable,
        maxScrolls: 40,
      );
    } on StateError {
      // Reached the end in this direction.
    }
  }
  await tester.ensureVisible(finder.first);
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
