import 'package:carryon/src/presentation/core/router/redirect_gate.dart';
import 'package:carryon/src/presentation/core/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final verify = Routes.verifyIdentity.path;
  final update = Routes.updateRequired.path;

  test('the update gate pins every path to its screen', () {
    expect(RedirectGate.redirect('/home', Routes.updateRequired), update);
    expect(RedirectGate.redirect('/order-form', Routes.updateRequired), update);
    expect(RedirectGate.redirect(update, Routes.updateRequired), isNull);
  });

  test('once open, the update screen sends the user home', () {
    expect(RedirectGate.redirect(update, Routes.home), Routes.home.path);
    expect(RedirectGate.redirect('/order-form', Routes.home), isNull);
  });

  test('identity verification is a normal screen, not a gate', () {
    expect(RedirectGate.redirect(verify, Routes.home), isNull);
  });
}
