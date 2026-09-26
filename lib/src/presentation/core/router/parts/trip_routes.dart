part of '../router.dart';

List<GoRoute> _tripRoutes(Ref ref) {
  return [
    GoRoute(
      path: Routes.tripForm.path,
      name: Routes.tripForm.name,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra;
        return MaterialPage(
          child: VerifiedOnly(
            child: TripFormPage(trip: extra is Trip ? extra : null),
          ),
        );
      },
    ),
  ];
}
