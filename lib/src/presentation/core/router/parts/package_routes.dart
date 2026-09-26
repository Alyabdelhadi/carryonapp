part of '../router.dart';

List<GoRoute> _packageRoutes(Ref ref) {
  return [
    GoRoute(
      path: Routes.matching.path,
      name: Routes.matching.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const MaterialPage(
        child: VerifiedOnly(child: MatchingPackagesPage()),
      ),
    ),
    GoRoute(
      path: Routes.orderDetail.path,
      name: Routes.orderDetail.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final order = state.extra;
        return MaterialPage(
          child: OrderDetailPage(
            orderId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            order: order is ParcelOrder ? order : null,
          ),
        );
      },
    ),
    GoRoute(
      path: Routes.orderForm.path,
      name: Routes.orderForm.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final args = extra is OrderFormArgs
            ? extra
            : const OrderFormArgs(flow: ParcelFlow.send);
        return MaterialPage(
          child: VerifiedOnly(child: OrderFormPage(args: args)),
        );
      },
    ),
    GoRoute(
      path: Routes.addressPicker.path,
      name: Routes.addressPicker.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final args = extra is AddressPickerArgs
            ? extra
            : AddressPickerArgs(title: context.l10n.coreAddressTitle);
        return MaterialPage(
          fullscreenDialog: true,
          child: AddressPickerPage(args: args),
        );
      },
    ),
    GoRoute(
      path: Routes.success.path,
      name: Routes.success.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => MaterialPage(
        child: SuccessPage(
          type: SuccessType.fromCode(state.pathParameters['type']),
        ),
      ),
    ),
  ];
}
