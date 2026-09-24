import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';

/// Sends the password reset link. Loading while in flight; the error state
/// carries the failure to show.
final forgotPasswordControllerProvider =
    AsyncNotifierProvider.autoDispose<ForgotPasswordController, void>(
      ForgotPasswordController.new,
    );

class ForgotPasswordController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Resolves true when the server accepted the request.
  Future<bool> sendResetLink(String email) async {
    state = const AsyncLoading();
    final result = await ref.read(sendResetLinkUseCaseProvider).call(email);
    if (!ref.mounted) return false;
    switch (result) {
      case Success():
        state = const AsyncData(null);
        return true;
      case Error(:final error):
        state = AsyncError(error, StackTrace.current);
        return false;
    }
  }
}
