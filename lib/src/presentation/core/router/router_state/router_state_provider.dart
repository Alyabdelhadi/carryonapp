import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../application_state/startup_provider/startup_provider.dart';
import '../routes.dart';

part 'router_state_provider.g.dart';

/// The gate destination the router enforces. CarryOn lets guests browse:
/// once startup completes the whole app is open, and screens that need an
/// account (packages, trips, account, posting an order) ask for login
/// themselves. So there are only two gates: splash while starting, home
/// afterwards.
@Riverpod(keepAlive: true)
Routes routerState(Ref ref) {
  final startup = ref.watch(startupProvider);
  if (startup.isLoading || startup.hasError) return .splash;

  return .home;
}
