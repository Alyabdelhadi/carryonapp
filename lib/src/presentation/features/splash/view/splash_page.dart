import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application_state/startup_provider/startup_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/failure_view.dart';
import '../widgets/animated_logo.dart';

/// Shown while `startupProvider` runs: a full black screen on which the
/// RR mark animates in. Retries in place if startup failed.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(startupProvider);
    return Scaffold(
      backgroundColor: context.color.background.splash,
      body: startup.when(
        loading: () => const Center(child: AnimatedLogo()),
        data: (_) => const Center(child: AnimatedLogo()),
        error: (error, _) => FailureView(
          error: error,
          onRetry: () => ref.invalidate(startupProvider),
        ),
      ),
    );
  }
}
