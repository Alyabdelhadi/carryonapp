import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/bootstrap.dart';
import 'src/core/config/app_config.dart';
import 'src/core/gen/l10n/app_localizations.dart';
import 'src/presentation/core/application_state/app_gate_provider/app_gate_provider.dart';
import 'src/presentation/core/application_state/localization_provider/localization_provider.dart';
import 'src/presentation/core/application_state/push_open_handler.dart';
import 'src/presentation/core/application_state/session_expiry_handler.dart';
import 'src/presentation/core/router/router.dart';
import 'src/presentation/core/router/router_state/router_state_provider.dart';
import 'src/presentation/core/theme/theme.dart';

Future<void> main() async {
  final container = await bootstrap();
  attachSessionExpiryHandler(container);
  attachPushOpenHandler(container);
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WHY: the router refreshes from a `ref.listen` on routerStateProvider,
    // and in Riverpod 3 an invalidated provider with only that listener is
    // not rebuilt on its own — the gate would stay on splash forever. A
    // widget watch forces the rebuild so the listener fires.
    ref.watch(routerStateProvider);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: ref.watch(localizationProvider),
        theme: context.lightTheme,
        darkTheme: context.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: ref.read(goRouterProvider),
        // WHY: on iOS/Android Flutter does not unfocus a text field when the
        // user taps elsewhere, so the keyboard stayed open. Taps that reach
        // this root detector hit no other gesture (buttons, fields win the
        // arena), so this only fires on empty space.
        builder: (context, child) => _GateRefresher(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Re-runs the blocking checks when the app comes back to the foreground:
/// the store version (the user may have just updated, or a new release
/// went out) and a pending identity review.
class _GateRefresher extends ConsumerStatefulWidget {
  const _GateRefresher({required this.child});

  final Widget? child;

  @override
  ConsumerState<_GateRefresher> createState() => _GateRefresherState();
}

class _GateRefresherState extends ConsumerState<_GateRefresher> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  void _onResume() {
    ref.invalidate(appUpdateProvider);
    if (ref.read(identityGateProvider).value == IdentityGate.underReview) {
      ref.invalidate(identityGateProvider);
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
