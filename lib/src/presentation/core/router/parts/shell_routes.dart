part of '../router.dart';

/// The four bottom tabs. The account tab renders the login screen while
/// signed out, exactly as the Ionic tab bar swapped "Account" for "Login".
StatefulShellRoute _shellRoutes(Ref ref) {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return NavigationShell(statefulNavigationShell: navigationShell);
    },
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.home.path,
            name: Routes.home.name,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage()),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.packages.path,
            name: Routes.packages.name,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PackagesPage()),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.trips.path,
            name: Routes.trips.name,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TripsPage()),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.account.path,
            name: Routes.account.name,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _AccountTab()),
          ),
        ],
      ),
    ],
  );
}

class _AccountTab extends ConsumerWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStatusProvider);
    return switch (session) {
      AsyncData(value: .authenticated) => const AccountPage(),
      _ => const LoginPage(embeddedInTab: true),
    };
  }
}
