import 'routes.dart';

/// The router's gating policy. Pure — no `Ref`, no `BuildContext` — so
/// the whole policy is unit-testable in isolation.
abstract final class RedirectGate {
  /// Enforces the [gate] destination for [path], or returns `null` to
  /// allow it.
  ///
  /// Splash, the mandatory update and the identity verification are hard
  /// gates: the user is pinned to that screen while the gate applies.
  /// Once open, only the gate paths and the bare `/` are redirected home;
  /// every other route is reachable, signed in or not — the screens that
  /// need a session prompt for login themselves.
  static String? redirect(String path, Routes gate) {
    return switch (gate) {
      .splash ||
      .updateRequired ||
      .verifyIdentity => path == gate.path ? null : gate.path,
      _ => _isGateOnlyPath(path) ? Routes.home.path : null,
    };
  }

  static bool _isGateOnlyPath(String path) =>
      path == Routes.splash.path ||
      path == Routes.updateRequired.path ||
      path == Routes.verifyIdentity.path ||
      path == '/';
}
