// Switches the app to Arabic through the UI and walks the main screens,
// taking a screenshot of each so the right-to-left layout can be reviewed.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/arabic_smoke_test.dart -d <udid>
//
// Screenshots land in build/screenshots/. Needs a signed-in session or the
// CARRYON_EMAIL / CARRYON_PASSWORD defines of send_package_test.dart.
import 'package:carryon/main.dart' as app;
import 'package:carryon/src/core/gen/l10n/app_localizations_ar.dart';
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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final ar = AppLocalizationsAr();

  testWidgets('switch to Arabic and visit every screen', (tester) async {
    await app.main();
    await tester.pump();

    await _pumpUntilAny(tester, [
      _navLabel('Login'),
      _navLabel('Account'),
      _navLabel(ar.login),
      _navLabel(ar.account),
    ]);

    final alreadyArabic =
        _navLabel(ar.account).evaluate().isNotEmpty ||
        _navLabel(ar.login).evaluate().isNotEmpty;

    if (!alreadyArabic) {
      if (_navLabel('Login').evaluate().isNotEmpty) {
        await tester.tap(_navLabel('Login'));
        await _pumpUntil(tester, _fieldWithHint('Email'));
        await tester.enterText(_fieldWithHint('Email'), _email);
        await tester.enterText(_fieldWithHint('Password'), _password);
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Login'));
        await _pumpUntil(tester, _navLabel('Account'), timeout: 40);
      }
      // Account → Language → العربية
      await tester.tap(_navLabel('Account'));
      await _pumpUntil(tester, find.text('Language'));
      await _scrollTo(tester, find.text('Language'));
      await tester.tap(find.text('Language'));
      await _pumpUntil(tester, find.text('العربية'));
      await tester.tap(find.text('العربية'));
      await _pumpUntil(tester, _navLabel(ar.account), timeout: 30);
    } else if (_navLabel(ar.login).evaluate().isNotEmpty) {
      await tester.tap(_navLabel(ar.login));
      await _pumpUntil(tester, _fieldWithHint(ar.authEmail));
      await tester.enterText(_fieldWithHint(ar.authEmail), _email);
      await tester.enterText(_fieldWithHint(ar.authPassword), _password);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, ar.login));
      await _pumpUntil(tester, _navLabel(ar.account), timeout: 40);
    }

    // Back to the top of the account page so the stats strip is visible.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1200));
    await _settle(tester, 2);
    await binding.takeScreenshot('ar_01_account');

    await tester.tap(_navLabel(ar.home));
    await _settle(tester, 4);
    await binding.takeScreenshot('ar_02_home');

    // Order form from the first service tile.
    final sendTile = find.textContaining('Send');
    if (sendTile.evaluate().isNotEmpty) {
      await _scrollTo(tester, sendTile.first);
      await tester.tap(sendTile.first);
      await _settle(tester, 3);
      await binding.takeScreenshot('ar_03_order_form');
      await _pop(tester);
      await _settle(tester, 1);
    }

    await tester.tap(_navLabel(ar.packages));
    await _settle(tester, 4);
    await binding.takeScreenshot('ar_04_packages');

    // Carried packages segment (carriers) shows route tiles with cities.
    final carried = find.text(ar.pkgCarriedPackages);
    if (carried.evaluate().isNotEmpty) {
      await tester.tap(carried.first);
      await _settle(tester, 4);
      await binding.takeScreenshot('ar_04b_carried_packages');
    }

    // Matching packages from the home header button.
    await tester.tap(_navLabel(ar.home));
    await _settle(tester, 2);
    final matching = find.byTooltip(ar.homeMatchingPackagesTooltip);
    if (matching.evaluate().isNotEmpty) {
      await tester.tap(matching.first);
      await _settle(tester, 5);
      await binding.takeScreenshot('ar_04c_matching');
      await _pop(tester);
      await _settle(tester, 1);
    }

    await tester.tap(_navLabel(ar.trips));
    await _settle(tester, 4);
    await binding.takeScreenshot('ar_05_trips');

    final addTrip = find.text(ar.tripAddNew);
    if (addTrip.evaluate().isNotEmpty) {
      await tester.tap(addTrip.first);
      await _settle(tester, 3);
      await binding.takeScreenshot('ar_06_trip_form');
      await _pop(tester);
      await _settle(tester, 1);
    }

    await tester.tap(_navLabel(ar.account));
    await _settle(tester, 2);
    await _scrollTo(tester, find.text(ar.language));
    await tester.tap(find.text(ar.language));
    await _settle(tester, 1);
    await binding.takeScreenshot('ar_07_language_sheet');
  });
}

Finder _navLabel(String label) => find.descendant(
  of: find.byType(GlassNavigationBar),
  matching: find.text(label),
);

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Future<void> _pop(WidgetTester tester) async {
  await Navigator.of(tester.element(find.byType(Scaffold).last)).maybePop();
}

Future<void> _settle(WidgetTester tester, int seconds) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump(const Duration(milliseconds: 300));
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
