import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../application_state/app_gate_provider/app_gate_provider.dart';
import '../../application_state/startup_provider/startup_provider.dart';
import '../routes.dart';

part 'router_state_provider.g.dart';

/// The gate destination the router enforces, in priority order:
///
/// 1. splash while starting (and while the first update / identity checks
///    run, so no screen flashes before a gate closes);
/// 2. the mandatory store update;
/// 3. identity verification, for a signed-in account that is not verified
///    while the admin has the Shufti check on;
/// 4. home: the whole app is open. Guests may browse; screens that need an
///    account ask for login themselves, and an account under review is
///    stopped at the send / receive / carry screens (`VerifiedOnly`).
@Riverpod(keepAlive: true)
Routes routerState(Ref ref) {
  final startup = ref.watch(startupProvider);
  if (startup.isLoading || startup.hasError) return .splash;

  final update = ref.watch(appUpdateProvider);
  final identity = ref.watch(identityGateProvider);
  if (update.value?.updateRequired ?? false) return .updateRequired;
  // First evaluation only; a re-check keeps its previous value meanwhile.
  if (!update.hasValue && !update.hasError) return .splash;
  if (!identity.hasValue && !identity.hasError) return .splash;
  if (identity.value == IdentityGate.required) return .verifyIdentity;

  return .home;
}
