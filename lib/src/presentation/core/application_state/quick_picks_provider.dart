import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/base/result.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../domain/entities/entities.dart';

/// The admin-edited weight and reward quick picks, loaded once per app run.
/// Failures keep the built-in defaults, so the chips never disappear.
final quickPicksLoaderProvider = FutureProvider<QuickPicks>((ref) async {
  final result = await ref.watch(getQuickPicksUseCaseProvider).call();
  return switch (result) {
    Success(:final data) => data,
    Error() => QuickPicks.defaults,
  };
});

/// The quick picks to show right now: the server's once loaded, the
/// defaults until then.
final quickPicksProvider = Provider<QuickPicks>((ref) {
  return ref.watch(quickPicksLoaderProvider).value ?? QuickPicks.defaults;
});
