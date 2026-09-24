// Walks the carrier wallet: Account → Wallet, request a payout, cancel it,
// screenshotting each step. Runs in English or Arabic (CARRYON_LANG=ar).
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/wallet_smoke_test.dart -d <udid> \
//     --dart-define=CARRYON_EMAIL=... --dart-define=CARRYON_PASSWORD=... \
//     --dart-define=CARRYON_DISABLE_PUSH=true [--dart-define=CARRYON_LANG=ar]
//
// The account needs an available balance above the payout minimum.
import 'package:carryon/main.dart' as app;
import 'package:carryon/src/core/gen/l10n/app_localizations.dart';
import 'package:carryon/src/core/gen/l10n/app_localizations_ar.dart';
import 'package:carryon/src/core/gen/l10n/app_localizations_en.dart';
import 'package:carryon/src/presentation/core/widgets/glass_navigation_bar.dart';
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
  final tag = 'wallet_$_lang';

  testWidgets('carrier wallet ($_lang)', (tester) async {
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

    await tester.tap(_navLabel(en.account));
    await _settle(tester, 2);
    if (_lang == 'ar') {
      await _scrollTo(tester, find.text(en.language));
      await tester.tap(find.text(en.language));
      await _pumpUntil(tester, find.text('العربية'));
      await tester.tap(find.text('العربية'));
      await _pumpUntil(tester, _navLabel(l10n.account), timeout: 30);
      await _settle(tester, 2);
    }

    await _scrollTo(tester, find.text(l10n.walTitle));
    await tester.tap(find.text(l10n.walTitle));
    await _pumpUntil(tester, find.text(l10n.walRequestPayout), timeout: 30);
    await _settle(tester, 2);
    await binding.takeScreenshot('${tag}_01_wallet');

    await tester.tap(find.widgetWithText(FilledButton, l10n.walRequestPayout));
    await _pumpUntil(tester, find.text(l10n.walSheetTitle));
    await _settle(tester, 1);
    await tester.tap(find.widgetWithText(ChoiceChip, 'OMT'));
    await _settle(tester, 1);
    await tester.enterText(_fieldWithLabel(l10n.walAmount('USD')), '30');
    await tester.enterText(
      _fieldWithLabel(l10n.walFieldFullName),
      'Ghaleb Kassab',
    );
    await tester.enterText(_fieldWithLabel(l10n.walFieldPhone), '70143335');
    await tester.pump();
    await binding.takeScreenshot('${tag}_02_request_sheet');

    await tester.tap(find.widgetWithText(FilledButton, l10n.walSubmit));
    await _pumpUntil(tester, find.text(l10n.walOpenPayout), timeout: 30);
    await _settle(tester, 2);
    await binding.takeScreenshot('${tag}_03_pending');

    await tester.tap(find.text(l10n.walCancelPayout).first);
    await _pumpUntil(tester, find.text(l10n.walCancelConfirm));
    await tester.tap(find.widgetWithText(FilledButton, l10n.yes).last);
    await _pumpUntil(
      tester,
      find.text(l10n.walPayoutCancelledToast),
      timeout: 30,
    );
    await _settle(tester, 2);
    await binding.takeScreenshot('${tag}_04_cancelled');
    expect(find.text(l10n.walOpenPayout), findsNothing);
  });
}

Finder _navLabel(String label) => find.descendant(
  of: find.byType(GlassNavigationBar),
  matching: find.text(label),
);

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _fieldWithLabel(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);

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
