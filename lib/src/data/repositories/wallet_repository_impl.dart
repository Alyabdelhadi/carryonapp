import '../../core/base/result.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/failures/business_failure.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../base/repository.dart';
import '../mappers/json_mappers.dart';
import '../services/network/exceptions.dart';
import '../services/network/rest_client.dart';

final class WalletRepositoryImpl extends Repository
    implements WalletRepository {
  WalletRepositoryImpl({required this.remote, required super.crashReporter});

  final RestClient remote;

  /// The wallet endpoints answer `msg: done` or `msg: <user-facing text>`.
  Map<String, dynamic> _done(Object? body) {
    final map = Json.asMap(body);
    final msg = Json.toStr(map['msg']);
    if (msg != 'done') {
      throw ApiResponseException(msg ?? 'Something went wrong');
    }
    return map;
  }

  @override
  Future<Result<WalletOverview, BusinessFailure>> overview(int userId) {
    return asyncGuard(() async {
      final response = await remote.wallet(userId);
      return WalletMapper.overview(_done(response.data));
    });
  }

  @override
  Future<Result<List<PayoutRequest>, BusinessFailure>> payouts(int userId) {
    return asyncGuard(() async {
      final response = await remote.payouts(userId);
      return Json.asList(_done(response.data)['payouts'])
          .map(WalletMapper.payout)
          .toList();
    });
  }

  @override
  Future<Result<PayoutRequest, BusinessFailure>> requestPayout({
    required int userId,
    required PayoutDraft draft,
  }) {
    return asyncGuard(() async {
      final response = await remote.requestPayout({
        'user_id': userId,
        'amount': draft.amount,
        'method': draft.method,
        'details': draft.details,
      });
      return WalletMapper.payout(Json.asMap(_done(response.data)['payout']));
    });
  }

  @override
  Future<Result<PayoutRequest, BusinessFailure>> cancelPayout({
    required int userId,
    required int payoutId,
  }) {
    return asyncGuard(() async {
      final response = await remote.cancelPayout(payoutId, {'user_id': userId});
      return WalletMapper.payout(Json.asMap(_done(response.data)['payout']));
    });
  }
}
