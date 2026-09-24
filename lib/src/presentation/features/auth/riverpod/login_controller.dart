import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';

/// Runs the login request. The state is loading while the request is in
/// flight and carries the [BusinessFailure] when it failed; the form itself
/// (controllers, obscure toggle) stays in the widget.
final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(
      LoginController.new,
    );

class LoginController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Resolves true when the session was created. On success the session
  /// providers are invalidated so the account tab re-renders.
  Future<bool> login({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await ref
        .read(loginUseCaseProvider)
        .call(email: email, password: password);
    if (!ref.mounted) return false;
    switch (result) {
      case Success():
        state = const AsyncData(null);
        ref.invalidate(sessionStatusProvider);
        return true;
      case Error(:final error):
        state = AsyncError(error, StackTrace.current);
        return false;
    }
  }
}
