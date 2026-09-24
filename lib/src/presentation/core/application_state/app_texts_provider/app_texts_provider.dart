import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/app_texts.dart';

part 'app_texts_provider.g.dart';

/// Admin-editable UI copy. Starts from the cached copy so screens render
/// immediately, then refreshes from the server once per process.
///
/// Read a label with `ref.watch(appTextsProvider).get('key', 'Fallback')`.
@Riverpod(keepAlive: true)
class AppTextsState extends _$AppTextsState {
  @override
  AppTexts build() {
    // ignore: unawaited_futures
    refresh();
    return ref.read(getAppTextsUseCaseProvider).cached;
  }

  Future<void> refresh() async {
    final fresh = await ref.read(getAppTextsUseCaseProvider).call();
    if (!ref.mounted) return;
    if (!fresh.isEmpty) state = fresh;
  }
}
