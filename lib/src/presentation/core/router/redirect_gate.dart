import 'routes.dart';

/// The router's gating policy. Pure — no `Ref`, no `BuildContext` — so
/// the whole policy is unit-testable in isolation.
abstract final class RedirectGate {
  /// Enforces the [gate] destination for [path], or returns `null` to
  /// allow it.
  ///
  /// Splash is a hard gate (the user is pinned there while the app
  /// starts). Once open, only the splash path and the bare `/` are
  /// redirected home; every other route is reachable, signed in or not —
  /// the screens that need a session prompt for login themselves.
  static String? redirect(String path, Routes gate) {
    return switch (gate) {
      .splash => path == Routes.splash.path ? null : Routes.splash.path,
      _ => _isGateOnlyPath(path) ? Routes.home.path : null,
    };
  }

  static bool _isGateOnlyPath(String path) =>
      path == Routes.splash.path || path == '/';
}
