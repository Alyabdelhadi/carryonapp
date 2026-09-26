import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';

/// The two steps the original signup showed while working: the Shufti
/// identity check, then the account creation. `SignupUseCase` runs both in
/// one call, so the UI lists both and highlights the first while waiting.
enum SignupStep { verifyingIdentity, creatingAccount }

/// Submits the signup form. `AsyncData(step)` with a non-null step is the
/// in-flight state (loading), `AsyncData(null)` is idle, `AsyncError`
/// carries the failure to show.
final signupControllerProvider =
    AsyncNotifierProvider.autoDispose<SignupController, SignupStep?>(
      SignupController.new,
    );

class SignupController extends AsyncNotifier<SignupStep?> {
  @override
  Future<SignupStep?> build() async => null;

  /// Resolves true when the account was created and the session stored.
  /// [checksIdentity] is false in live verification mode, where signup
  /// only creates the account.
  Future<bool> signup(SignupInput input, {bool checksIdentity = true}) async {
    state = AsyncData(
      checksIdentity
          ? SignupStep.verifyingIdentity
          : SignupStep.creatingAccount,
    );
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
