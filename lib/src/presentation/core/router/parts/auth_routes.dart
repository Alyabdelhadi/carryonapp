part of '../router.dart';

List<GoRoute> _authRoutes(Ref ref) {
  return [
    GoRoute(
      path: Routes.login.path,
      name: Routes.login.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          const MaterialPage(fullscreenDialog: true, child: LoginPage()),
    ),
    GoRoute(
      path: Routes.signup.path,
      name: Routes.signup.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const MaterialPage(child: SignupPage()),
    ),
    GoRoute(
      path: Routes.forgotPassword.path,
      name: Routes.forgotPassword.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          const MaterialPage(child: ForgotPasswordPage()),
    ),
  ];
}
