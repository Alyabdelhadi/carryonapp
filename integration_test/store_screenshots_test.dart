// Store screenshots: signs in and captures the main screens at the device's
// native resolution (run it on an iPhone 17 Pro Max for the 6.9" set).
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/store_screenshots_test.dart -d <udid> \
//     --dart-define=CARRYON_EMAIL=... --dart-define=CARRYON_PASSWORD=... \
//     --dart-define=CARRYON_DISABLE_PUSH=true [--dart-define=CARRYON_LANG=ar]
//
// Screenshots land in build/screenshots/store_<lang>_NN_<screen>.png.
import 'package:carryon/main.dart' as app;
import 'package:carryon/src/core/gen/l10n/app_localizations.dart';
import 'package:carryon/src/core/gen/l10n/app_localizations_ar.dart';
import 'package:carryon/src/core/gen/l10n/app_localizations_en.dart';
import 'package:carryon/src/presentation/core/widgets/glass_navigation_bar.dart';
import 'package:carryon/src/presentation/core/widgets/loading_indicator.dart';
import 'package:carryon/src/presentation/features/home/widgets/home_loading_placeholder.dart';
import 'package:carryon/src/presentation/features/home/widgets/service_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _email = String.fromEnvironment('CARRYON_EMAIL', defaultValue: '');
const _password = String.fromEnvironment('CARRYON_PASSWORD', defaultValue: '');
const _lang = String.fromEnvironment('CARRYON_LANG', defaultValue: 'en');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final en = AppLocalizationsEn();
  final AppLocalizations l10n = _lang == 'ar' ? AppLocalizationsAr() : en;
  final tag = 'store_$_lang';

  testWidgets('store screenshots ($_lang)', (tester) async {
    await app.main();
    await tester.pump();
    await _pumpUntilAny(tester, [_navLabel(en.login), _navLabel(en.account)]);

    if (_navLabel(en.login).evaluate().isNotEmpty) {
      await tester.tap(_navLabel(en.login));
      await _pumpUntil(tester, _fieldWithHint(en.authEmail));
      await tester.enterText(_fieldWithHint(en.authEmail), _email);
      await tester.enterText(_fieldWithHint(en.authPassword), _password);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, en.login));
      await _pumpUntil(tester, _navLabel(en.account), timeout: 40);
    }

    if (_lang == 'ar') {
      await tester.tap(_navLabel(en.account));
      await _settle(tester, 2);
      await _scrollTo(tester, find.text(en.language));
      await tester.tap(find.text(en.language));
      await _pumpUntil(tester, find.text('العربية'));
      await tester.tap(find.text('العربية'));
      await _pumpUntil(tester, _navLabel(l10n.account), timeout: 30);
    }

    // 01 Home
    await tester.tap(_navLabel(l10n.home));
    await _waitLoaded(tester);
    await _settle(tester, 3);
    await binding.takeScreenshot('${tag}_01_home');

    // 02 Send a package form
    final sendCard = find.byType(ServiceCard);
    if (sendCard.evaluate().isNotEmpty) {
      await tester.tap(sendCard.first);
      await _pumpUntil(tester, find.byType(TextField), timeout: 30);
      await _waitLoaded(tester);
      await _settle(tester, 2);
      await binding.takeScreenshot('${tag}_02_send_package');
      await _pop(tester);
      await _settle(tester, 1);
    }

    // 03 Packages
    await tester.tap(_navLabel(l10n.packages));
    await _waitLoaded(tester);
    await _settle(tester, 2);
    await binding.takeScreenshot('${tag}_03_packages');

    // 04 First package detail
    final tracking = find.textContaining(
      _lang == 'ar' ? 'رقم التتبع' : 'Tracking #',
    );
    if (tracking.evaluate().isNotEmpty) {
      await tester.tap(tracking.first);
      await _waitLoaded(tester);
      await _settle(tester, 3);
      await binding.takeScreenshot('${tag}_04_package_detail');
      await _pop(tester);
      await _settle(tester, 1);
    }

    // 05 Trips
    await tester.tap(_navLabel(l10n.trips));
    await _waitLoaded(tester);
    await _settle(tester, 2);
    await binding.takeScreenshot('${tag}_05_trips');

    // 06 Matching packages (from the home header button)
    await tester.tap(_navLabel(l10n.home));
    await _settle(tester, 2);
    final matching = find.byTooltip(l10n.homeMatchingPackagesTooltip);
    if (matching.evaluate().isNotEmpty) {
      await tester.tap(matching.first);
      await _waitLoaded(tester);
      await _settle(tester, 2);
      await binding.takeScreenshot('${tag}_06_matching');
      await _pop(tester);
      await _settle(tester, 1);
    }

    // 07 Account
    await tester.tap(_navLabel(l10n.account));
    await _waitLoaded(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1200));
    await _settle(tester, 2);
    await binding.takeScreenshot('${tag}_07_account');

    // 08 Wallet (only when the row is shown)
    final wallet = find.text(l10n.walTitle);
    if (wallet.evaluate().isNotEmpty) {
      await _scrollTo(tester, wallet);
      await tester.tap(wallet);
      await _waitLoaded(tester);
      await _settle(tester, 2);
      await binding.takeScreenshot('${tag}_08_wallet');
      await _pop(tester);
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

/// Pumps until no loading indicator or placeholder is on screen (production
/// responses take a few seconds).
Future<void> _waitLoaded(WidgetTester tester, {int timeout = 40}) async {
  final deadline = DateTime.now().add(Duration(seconds: timeout));
  await tester.pump(const Duration(milliseconds: 500));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    final busy =
        find.byType(LoadingIndicator).evaluate().isNotEmpty ||
        find.byType(HomeLoadingPlaceholder).evaluate().isNotEmpty ||
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.byType(LinearProgressIndicator).evaluate().isNotEmpty;
    if (!busy) return;
  }
}

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
