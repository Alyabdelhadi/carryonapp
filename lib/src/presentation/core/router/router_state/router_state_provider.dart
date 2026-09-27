import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../application_state/app_gate_provider/app_gate_provider.dart';
import '../../application_state/startup_provider/startup_provider.dart';
import '../routes.dart';

part 'router_state_provider.g.dart';

/// The gate destination the router enforces, in priority order:
///
/// 1. splash while starting (and while the first update check runs, so no
///    screen flashes before the gate closes);
/// 2. the mandatory store update;
/// 3. home: the whole app is open. Guests may browse; screens that need an
///    account ask for login themselves, and an account that is not
///    verified yet is stopped at the send / receive / carry screens
///    (`VerifiedOnly`), which lead to the verification screen.
@Riverpod(keepAlive: true)
Routes routerState(Ref ref) {
  final startup = ref.watch(startupProvider);
  if (startup.isLoading || startup.hasError) return .splash;

  final update = ref.watch(appUpdateProvider);
  if (update.value?.updateRequired ?? false) return .updateRequired;
  // First evaluation only; a re-check keeps its previous value meanwhile.
  if (!update.hasValue && !update.hasError) return .splash;

  return .home;
}
