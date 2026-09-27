import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';

/// Submits the signup form. Signup runs no identity check: the account
/// verifies later (`VerifyIdentityPage`), before its first send, receive
/// or carry.
final signupControllerProvider =
    AsyncNotifierProvider.autoDispose<SignupController, void>(
      SignupController.new,
    );

class SignupController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Resolves true when the account was created and the session stored.
  Future<bool> signup(SignupInput input) async {
    state = const AsyncLoading();
    final result = await ref.read(signupUseCaseProvider).call(input);
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
