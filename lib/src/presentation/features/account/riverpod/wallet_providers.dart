import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../domain/failures/business_failure.dart';

/// Balance, rules, latest movements and the open payout of one user.
final walletOverviewProvider = FutureProvider.autoDispose
    .family<WalletOverview, int>((ref, userId) async {
      final result = await ref
          .watch(getWalletOverviewUseCaseProvider)
          .call(userId);
      return switch (result) {
        Success(:final data) => data,
        Error(:final error) => throw error,
      };
    });

/// Payout requests of one user, newest first.
final walletPayoutsProvider = FutureProvider.autoDispose
    .family<List<PayoutRequest>, int>((ref, userId) async {
      final result = await ref.watch(getPayoutsUseCaseProvider).call(userId);
      return switch (result) {
        Success(:final data) => data,
        Error(:final error) => throw error,
      };
    });

void invalidateWallet(Ref ref) {
  ref
    ..invalidate(walletOverviewProvider)
    ..invalidate(walletPayoutsProvider);
}

/// Request / cancel a payout; the loading flag drives the busy overlay.
class PayoutActions extends AsyncNotifier<PayoutRequest?> {
  @override
  Future<PayoutRequest?> build() async => null;

  Future<Result<PayoutRequest, BusinessFailure>> request({
    required int userId,
    required PayoutDraft draft,
  }) {
    return _run(
      () => ref
          .read(requestPayoutUseCaseProvider)
          .call(userId: userId, draft: draft),
    );
  }

  Future<Result<PayoutRequest, BusinessFailure>> cancel({
    required int userId,
    required int payoutId,
  }) {
    return _run(
      () => ref
          .read(cancelPayoutUseCaseProvider)
          .call(userId: userId, payoutId: payoutId),
    );
  }

  Future<Result<PayoutRequest, BusinessFailure>> _run(
    Future<Result<PayoutRequest, BusinessFailure>> Function() operation,
  ) async {
    state = const AsyncValue.loading();
    final result = await operation();
    if (!ref.mounted) return result;
    switch (result) {
      case Success(:final data):
        state = AsyncValue.data(data);
        invalidateWallet(ref);
      case Error(:final error):
        state = AsyncValue.error(error, StackTrace.current);
    }
    return result;
  }
}

final payoutActionsProvider =
    AsyncNotifierProvider.autoDispose<PayoutActions, PayoutRequest?>(
      PayoutActions.new,
    );
