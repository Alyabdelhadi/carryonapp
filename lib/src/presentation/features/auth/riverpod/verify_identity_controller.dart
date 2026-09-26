import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/app_gate_provider/app_gate_provider.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';

/// Sends a new selfie + ID for the signed-in account, or (live mode) opens
/// a Shufti session. `AsyncLoading` while the backend works,
/// `AsyncData(user)` with the updated user after a photo check,
/// `AsyncError` with the failure to show.
final verifyIdentityControllerProvider =
    AsyncNotifierProvider.autoDispose<VerifyIdentityController, AppUser?>(
      VerifyIdentityController.new,
    );

class VerifyIdentityController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async => null;

  /// Resolves to the updated user (verified or under review), or null when
  /// the check did not pass.
  Future<AppUser?> submit({
    required String selfiePath,
    required String identityPath,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || state.isLoading) return null;
    state = const AsyncLoading();
    final result = await ref
        .read(verifyIdentityUseCaseProvider)
        .call(
          userId: userId,
          selfiePath: selfiePath,
          identityPath: identityPath,
        );
    if (!ref.mounted) return null;
    switch (result) {
      case Success(:final data):
        state = AsyncData(data);
        // the router leaves the gate once this resolves
        ref.invalidate(identityGateProvider);
        return data;
      case Error(:final error):
        state = AsyncError(error, StackTrace.current);
        return null;
    }
  }

  /// Live mode: opens a Shufti session and resolves to the page the user
  /// completes in a browser, or null (nothing left to verify, or failed).
  Future<Uri?> startLive(String languageCode) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || state.isLoading) return null;
    state = const AsyncLoading();
    final result = await ref
        .read(verifyIdentityUseCaseProvider)
        .startLive(userId: userId, languageCode: languageCode);
    if (!ref.mounted) return null;
    switch (result) {
      case Success(:final data):
        state = const AsyncData(null);
        // already verified or under review: let the gate move on
        if (data == null) ref.invalidate(identityGateProvider);
        return data;
      case Error(:final error):
        state = AsyncError(error, StackTrace.current);
        return null;
    }
  }
}

/// "Check again" on the under-review screen: the backend asks Shufti for
/// the verdict and the gate follows.
Future<IdentityStatus?> refreshIdentityStatus(WidgetRef ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return null;
  final result = await ref.read(verifyIdentityUseCaseProvider).refresh(userId);
  ref.invalidate(identityGateProvider);
  return switch (result) {
    Success(:final data) => data.identityStatus,
    Error() => null,
  };
}
