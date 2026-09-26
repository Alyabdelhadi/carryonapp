// The order form and carbon calculator show the admin's weights and
// rewards (local backend; the test changes are made in its database
// beforehand: reward 150 -> 250, a new 25 kg weight).
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/quick_picks_test.dart -d <udid> \
//     --dart-define=CARRYON_API_BASE=http://127.0.0.1:8000/api \
//     --dart-define=CARRYON_DISABLE_PUSH=true \
//     --dart-define=CARRYON_EMAIL=<account> --dart-define=CARRYON_PASSWORD=<pw>
import 'package:carryon/main.dart' as app;
import 'package:carryon/src/core/base/result.dart';
import 'package:carryon/src/core/di/dependency_injection.dart';
import 'package:carryon/src/domain/entities/entities.dart';
import 'package:carryon/src/presentation/core/router/route_args.dart';
import 'package:carryon/src/presentation/core/router/router.dart';
import 'package:carryon/src/presentation/core/router/routes.dart';
import 'package:carryon/src/presentation/core/widgets/glass_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _email = String.fromEnvironment('CARRYON_EMAIL');
const _password = String.fromEnvironment('CARRYON_PASSWORD');
const _orderId = int.fromEnvironment('CARRYON_ORDER_ID');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('quick picks come from the admin', (tester) async {
    await app.main();
    await tester.pump();
    await _pumpUntilAny(tester, [_navLabel('Login'), _navLabel('Account')]);
    if (_navLabel('Login').evaluate().isNotEmpty) {
      await tester.tap(_navLabel('Login'));
      await _pumpUntilAny(tester, [_fieldWithHint('Email')]);
      await tester.enterText(_fieldWithHint('Email'), _email);
      await tester.enterText(_fieldWithHint('Password'), _password);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await _pumpUntilAny(tester, [_navLabel('Account')], timeout: 40);
    }
    await _settle(tester, 3);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GlassNavigationBar)),
    );
    final router = container.read(goRouterProvider);

    // edit an existing order: step 1 is filled, so "Next" opens step 2
    final order = switch (await container
        .read(fetchParcelOrderUseCaseProvider)
        .call(_orderId)) {
      Success(:final data) => data,
      Error(:final error) => throw TestFailure('order: $error'),
    };
    // ignore: unawaited_futures
    router.pushNamed(
      Routes.orderForm.name,
      extra: OrderFormArgs(flow: ParcelFlow.send, order: order),
    );
    await _settle(tester, 4);
    await tester.tap(find.text('Next'));
    await _settle(tester, 3);
    _mark('order-form-step-2');
    await _settle(tester, 2);
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('250'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('150'), findsNothing);
    _mark('order-form-rewards');
    await tester.scrollUntilVisible(
      find.text('25'),
      -300,
      scrollable: scrollable,
    );
    _mark('order-form-weights');
    await _settle(tester, 2);

    router.pop();
    // ignore: unawaited_futures
    router.pushNamed(Routes.carbonCalculator.name);
    await _settle(tester, 3);
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await _settle(tester, 2);
    await tester.scrollUntilVisible(
      find.text('25 kg').last,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    _mark('calculator-weights');
    await _settle(tester, 3);
  });
}

Finder _navLabel(String label) => find.descendant(
  of: find.byType(GlassNavigationBar),
  matching: find.text(label),
);

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

void _mark(String step) => debugPrint('E2E: $step');

Future<void> _settle(WidgetTester tester, int seconds) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

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
