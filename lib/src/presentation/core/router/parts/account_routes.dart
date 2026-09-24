part of '../router.dart';

List<GoRoute> _accountRoutes(Ref ref) {
  return [
    GoRoute(
      path: Routes.profile.path,
      name: Routes.profile.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const MaterialPage(child: ProfilePage()),
    ),
    GoRoute(
      path: Routes.addresses.path,
      name: Routes.addresses.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          const MaterialPage(child: AddressesPage()),
    ),
    GoRoute(
      path: Routes.addressForm.path,
      name: Routes.addressForm.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra;
        return MaterialPage(
          child: AddressFormPage(address: extra is Address ? extra : null),
        );
      },
    ),
    GoRoute(
      path: Routes.wallet.path,
      name: Routes.wallet.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const MaterialPage(child: WalletPage()),
    ),
    GoRoute(
      path: Routes.carbonCalculator.path,
      name: Routes.carbonCalculator.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra;
        return MaterialPage(
          child: CarbonCalculatorPage(
            args: extra is CarbonCalculatorArgs ? extra : null,
          ),
        );
      },
    ),
  ];
}
