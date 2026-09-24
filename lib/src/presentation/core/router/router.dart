import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/extensions/localization.dart';
import '../../../core/extensions/riverpod_extensions.dart';
import '../../../domain/entities/entities.dart';
import '../../features/account/view/account_page.dart';
import '../../features/account/view/address_form_page.dart';
import '../../features/account/view/addresses_page.dart';
import '../../features/account/view/carbon_calculator_page.dart';
import '../../features/account/view/profile_page.dart';
import '../../features/auth/view/forgot_password_page.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/auth/view/signup_page.dart';
import '../../features/home/view/home_page.dart';
import '../../features/packages/view/address_picker_page.dart';
import '../../features/packages/view/matching_packages_page.dart';
import '../../features/packages/view/order_detail_page.dart';
import '../../features/packages/view/order_form_page.dart';
import '../../features/packages/view/packages_page.dart';
import '../../features/packages/view/success_page.dart';
import '../../features/splash/view/splash_page.dart';
import '../../features/trips/view/trip_form_page.dart';
import '../../features/trips/view/trips_page.dart';
import '../application_state/session_status_provider/session_status_provider.dart';
import '../widgets/navigation_shell.dart';
import '../widgets/not_found_screen.dart';
import 'redirect_gate.dart';
import 'route_args.dart';
import 'router_state/router_state_provider.dart';
import 'routes.dart';

part 'parts/account_routes.dart';
part 'parts/auth_routes.dart';
part 'parts/package_routes.dart';
part 'parts/shell_routes.dart';
part 'parts/trip_routes.dart';
part 'router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'Root');

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final refresh = ref.asListenable(routerStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    initialLocation: Routes.splash.path,
    redirect: (context, state) =>
        RedirectGate.redirect(state.uri.path, ref.read(routerStateProvider)),
    errorBuilder: (context, state) => NotFoundScreen(uri: state.uri),
    routes: [
      GoRoute(
        path: Routes.splash.path,
        name: Routes.splash.name,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashPage()),
      ),
      _shellRoutes(ref),
      ..._authRoutes(ref),
      ..._packageRoutes(ref),
      ..._tripRoutes(ref),
      ..._accountRoutes(ref),
    ],
  );
}
