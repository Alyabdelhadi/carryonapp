import '../../core/base/result.dart';
import '../entities/wallet.dart';
import '../failures/business_failure.dart';

abstract interface class WalletRepository {
  /// Balance, rules, latest movements and the open payout request.
  Future<Result<WalletOverview, BusinessFailure>> overview(int userId);

  /// Payout requests, newest first.
  Future<Result<List<PayoutRequest>, BusinessFailure>> payouts(int userId);

  /// Creates a payout request; the backend reserves the amount at once.
  Future<Result<PayoutRequest, BusinessFailure>> requestPayout({
    required int userId,
    required PayoutDraft draft,
  });

  /// Cancels a pending request and returns the money to the balance.
  Future<Result<PayoutRequest, BusinessFailure>> cancelPayout({
    required int userId,
    required int payoutId,
  });
}
