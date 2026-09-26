// Walks the identity gates against a local backend (see local-dev/start.sh
// in the backend). The native photo picker cannot be driven, so the photos
// are handed to the Verify screen's controller as file paths on the host
// (the simulator reads the Mac's filesystem). Prints `E2E:` markers so a
// script can screenshot each step with `xcrun simctl io <udid> screenshot`.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/identity_gate_test.dart -d <udid> \
//     --dart-define=CARRYON_API_BASE=http://127.0.0.1:8000/api \
//     --dart-define=CARRYON_UPLOAD_BASE=http://127.0.0.1:8000/upload \
//     --dart-define=CARRYON_DISABLE_PUSH=true \
//     --dart-define=CARRYON_SCENARIO=verify \
//     --dart-define=CARRYON_EMAIL=<account> --dart-define=CARRYON_PASSWORD=<pw> \
//     --dart-define=CARRYON_SELFIE=/path/selfie.jpg \
//     --dart-define=CARRYON_ID=/path/passport.jpg
//
// Scenarios (the account's state is set on the backend beforehand):
//   verify       unverified account -> Verify screen -> verified -> badge
//   under_review pending account -> "Send a package" shows Under review
//   update       newer store version -> Update required screen
import 'package:carryon/main.dart' as app;
import 'package:carryon/src/presentation/core/widgets/glass_navigation_bar.dart';
import 'package:carryon/src/presentation/features/auth/riverpod/verify_identity_controller.dart';
import 'package:carryon/src/presentation/features/auth/view/verify_identity_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _scenario = String.fromEnvironment(
  'CARRYON_SCENARIO',
  defaultValue: 'verify',
);
const _email = String.fromEnvironment('CARRYON_EMAIL');
const _password = String.fromEnvironment(
  'CARRYON_PASSWORD',
  defaultValue: 'secret123',
);
const _selfie = String.fromEnvironment('CARRYON_SELFIE');
const _identity = String.fromEnvironment('CARRYON_ID');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('identity gate: $_scenario', (tester) async {
    await app.main();
    await tester.pump();
    if (_scenario != 'update') await _signInIfNeeded(tester);

    switch (_scenario) {
      case 'verify':
        await _pumpUntil(tester, find.text('Verify your identity'));
        _mark('verify-screen');
        await _settle(tester, 4);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(VerifyIdentityPage)),
        );
        final started = DateTime.now();
        final pending = container
            .read(verifyIdentityControllerProvider.notifier)
            .submit(selfiePath: _selfie, identityPath: _identity);
        await _pumpUntil(
          tester,
          find.textContaining('Verifying your identity'),
        );
        _mark('verifying-overlay');
        await _settle(tester, 3);
        await _pumpUntil(tester, _navLabel('Account'), timeout: 150);
        final user = await pending;
        final seconds = DateTime.now().difference(started).inSeconds;
        _mark('home status=${user?.identityStatus.name} seconds=$seconds');
        expect(user?.isVerified, isTrue);
        await _settle(tester, 3);

        await tester.tap(_navLabel('Account'));
        await _pumpUntil(tester, find.text('Verified'));
        _mark('account-badge');
        await _settle(tester, 6);

      case 'under_review':
        await _pumpUntil(tester, _navLabel('Home'));
        await tester.tap(_navLabel('Home'));
        await _pumpUntil(tester, find.text('Send a package'));
        await _settle(tester, 2);
        await tester.tap(find.text('Send a package'));
        await _pumpUntil(tester, find.text('Account under review'));
        _mark('under-review');
        await _settle(tester, 6);

      case 'update':
        await _pumpUntil(tester, find.text('Update required'));
        _mark('update-required');
        await _settle(tester, 6);
    }
  });
}

/// Signs in through the Login screen when the app starts as a guest; the
/// identity gate then decides where the user lands.
Future<void> _signInIfNeeded(WidgetTester tester) async {
  final login = _navLabel('Login');
  final landed = [
    login,
    _navLabel('Account'),
    find.text('Verify your identity'),
  ];
  await _pumpUntilAny(tester, landed);
  if (login.evaluate().isEmpty) return;
  await tester.tap(login);
  await _pumpUntil(tester, _fieldWithHint('Email'));
  await tester.enterText(_fieldWithHint('Email'), _email);
  await tester.enterText(_fieldWithHint('Password'), _password);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Login'));
  await _pumpUntilAny(tester, landed.sublist(1), timeout: 40);
  _mark('signed-in');
}

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Future<void> _pumpUntilAny(
  WidgetTester tester,
  List<Finder> finders, {
  int timeout = 40,
}) async {
  final deadline = DateTime.now().add(Duration(seconds: timeout));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finders.any((f) => f.evaluate().isNotEmpty)) return;
  }
  throw TestFailure('Timed out waiting for any of $finders');
}

void _mark(String step) => debugPrint('E2E: $step');

Finder _navLabel(String label) => find.descendant(
  of: find.byType(GlassNavigationBar),
  matching: find.text(label),
);

Future<void> _settle(WidgetTester tester, int seconds) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int timeout = 40,
}) async {
  final deadline = DateTime.now().add(Duration(seconds: timeout));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}
