import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/bootstrap.dart';
import 'src/core/config/app_config.dart';
import 'src/core/gen/l10n/app_localizations.dart';
import 'src/presentation/core/application_state/localization_provider/localization_provider.dart';
import 'src/presentation/core/application_state/push_open_handler.dart';
import 'src/presentation/core/router/router.dart';
import 'src/presentation/core/router/router_state/router_state_provider.dart';
import 'src/presentation/core/theme/theme.dart';

Future<void> main() async {
  final container = await bootstrap();
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
      ),
    );
  }
}
