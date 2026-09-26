import 'package:carryon/src/presentation/core/router/redirect_gate.dart';
import 'package:carryon/src/presentation/core/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final verify = Routes.verifyIdentity.path;
  final update = Routes.updateRequired.path;

  test('blocking gates pin every path to their screen', () {
    for (final gate in [Routes.updateRequired, Routes.verifyIdentity]) {
      expect(RedirectGate.redirect('/home', gate), gate.path);
      expect(RedirectGate.redirect('/order-form', gate), gate.path);
      expect(RedirectGate.redirect(gate.path, gate), isNull);
    }
  });

  test('once open, gate screens send the user home', () {
    expect(RedirectGate.redirect(verify, Routes.home), Routes.home.path);
    expect(RedirectGate.redirect(update, Routes.home), Routes.home.path);
    expect(RedirectGate.redirect('/order-form', Routes.home), isNull);
  });
}
