import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../entities/parcel_order.dart';
import '../entities/parcel_order_draft.dart';
import '../failures/business_failure.dart';

abstract interface class ParcelOrderRepository {
  Future<Result<ParcelOrder, BusinessFailure>> create(ParcelOrderDraft draft);

  Future<Result<ParcelOrder, BusinessFailure>> update(ParcelOrderDraft draft);

  /// Orders the user posted (as sender or receiver).
  Future<Result<List<ParcelOrder>, BusinessFailure>> myCreated(int userId);

  /// Orders the user accepted to carry.
  Future<Result<List<ParcelOrder>, BusinessFailure>> myCarried(int userId);

  Future<Result<List<ParcelOrder>, BusinessFailure>> unassigned();

  /// Unassigned orders whose route matches one of the carrier's trips.
  /// An empty list when the carrier has no trips.
  Future<Result<List<ParcelOrder>, BusinessFailure>> matchingForCarrier(
    int carrierId,
  );

  Future<Result<Unit, BusinessFailure>> markMatchingRead({
    required int carrierId,
    required int orderId,
  });

  /// Carrier accepts the order.
  Future<Result<ParcelOrder, BusinessFailure>> assign({
    required int carrierId,
    required int orderId,
  });

  /// Carrier drops the order back to the pool.
  Future<Result<ParcelOrder, BusinessFailure>> unassign({
    required int carrierId,
    required int orderId,
  });

  Future<Result<ParcelOrder, BusinessFailure>> pickup({
    required int carrierId,
    required int orderId,
  });

  Future<Result<ParcelOrder, BusinessFailure>> transit({
    required int carrierId,
    required int orderId,
  });

  Future<Result<ParcelOrder, BusinessFailure>> deliver({
    required int carrierId,
    required int orderId,
  });

  /// Creator cancels the order.
  Future<Result<ParcelOrder, BusinessFailure>> cancel({
    required int userId,
    required int orderId,
  });

  /// Creator moves the "needed before" date; an expired order becomes
  /// unassigned again.
  Future<Result<ParcelOrder, BusinessFailure>> extend({
    required int userId,
    required int orderId,
    required DateTime neededBefore,
  });
}
