import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/dependency_injection.dart';
import '../app_texts_provider/app_texts_provider.dart';
import '../localization_provider/localization_provider.dart';

part 'startup_provider.g.dart';

/// Everything that must be ready before the first real screen: the
/// preference store, the locale, the cached UI copy, and the push topic
/// subscriptions. Network work here is best effort and never blocks
/// startup on failure.
@Riverpod(keepAlive: true)
Future<void> startup(Ref ref) async {
  ref.onDispose(() {
    ref.invalidate(sharedPreferencesProvider);
  });

  // The splash logo animation needs this long to play; startup work runs
  // underneath it and the gate opens when both are done.
  final minimumSplash = Future<void>.delayed(
    const Duration(milliseconds: 2200),
  );

  await ref.watch(sharedPreferencesProvider.future);

  await ref.read(localizationProvider.notifier).setCurrentLocal();

  // Warm the texts from cache synchronously; the provider refreshes from
  // the server on its own.
  ref.read(appTextsStateProvider);

  // Push permission + topics, in the background.
  // ignore: unawaited_futures
  ref.read(setupPushUseCaseProvider).call();

  await minimumSplash;
}
