import '../../core/base/result.dart';
import '../entities/wallet.dart';
import '../failures/business_failure.dart';
import '../repositories/wallet_repository.dart';

final class GetWalletOverviewUseCase {
  GetWalletOverviewUseCase(this.wallet);

  final WalletRepository wallet;

  Future<Result<WalletOverview, BusinessFailure>> call(int userId) =>
      wallet.overview(userId);
}

final class GetPayoutsUseCase {
  GetPayoutsUseCase(this.wallet);

  final WalletRepository wallet;

  Future<Result<List<PayoutRequest>, BusinessFailure>> call(int userId) =>
      wallet.payouts(userId);
}

final class RequestPayoutUseCase {
  RequestPayoutUseCase(this.wallet);

  final WalletRepository wallet;

  Future<Result<PayoutRequest, BusinessFailure>> call({
    required int userId,
    required PayoutDraft draft,
  }) => wallet.requestPayout(userId: userId, draft: draft);
}

final class CancelPayoutUseCase {
  CancelPayoutUseCase(this.wallet);

  final WalletRepository wallet;

  Future<Result<PayoutRequest, BusinessFailure>> call({
    required int userId,
    required int payoutId,
  }) => wallet.cancelPayout(userId: userId, payoutId: payoutId);
}
