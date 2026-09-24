import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../entities/parcel_order.dart';
import '../entities/parcel_order_draft.dart';
import '../failures/business_failure.dart';
import '../repositories/parcel_order_repository.dart';

/// Creates or updates depending on whether the draft carries an order id.
final class SaveParcelOrderUseCase {
  SaveParcelOrderUseCase(this.orders);

  final ParcelOrderRepository orders;

  Future<Result<ParcelOrder, BusinessFailure>> call(ParcelOrderDraft draft) {
    return draft.isEdit ? orders.update(draft) : orders.create(draft);
  }
}

final class GetMyCreatedOrdersUseCase {
  GetMyCreatedOrdersUseCase(this.orders);

  final ParcelOrderRepository orders;

  Future<Result<List<ParcelOrder>, BusinessFailure>> call(int userId) =>
      orders.myCreated(userId);
}

final class GetMyCarriedOrdersUseCase {
  GetMyCarriedOrdersUseCase(this.orders);

  final ParcelOrderRepository orders;

  Future<Result<List<ParcelOrder>, BusinessFailure>> call(int userId) =>
      orders.myCarried(userId);
}

/// Matching orders for a carrier, minus the ones the carrier posted
/// themselves (the original app filtered those client-side).
final class GetMatchingOrdersUseCase {
  GetMatchingOrdersUseCase(this.orders);

  final ParcelOrderRepository orders;

  Future<Result<List<ParcelOrder>, BusinessFailure>> call(int carrierId) async {
    final result = await orders.matchingForCarrier(carrierId);
    return switch (result) {
      Success(:final data) => Success(
        data.where((o) => o.userId != carrierId).toList(),
      ),
      Error(:final error) => Error(error),
    };
  }
}

final class MarkMatchingOrderReadUseCase {
  MarkMatchingOrderReadUseCase(this.orders);

  final ParcelOrderRepository orders;

  Future<Result<Unit, BusinessFailure>> call({
    required int carrierId,
    required int orderId,
  }) {
    return orders.markMatchingRead(carrierId: carrierId, orderId: orderId);
  }
}

/// The carrier-side and creator-side status transitions.
enum ParcelOrderAction { accept, drop, pickup, transit, deliver, cancel }

final class TransitionParcelOrderUseCase {
  TransitionParcelOrderUseCase(this.orders);

  final ParcelOrderRepository orders;

  Future<Result<ParcelOrder, BusinessFailure>> call({
    required ParcelOrderAction action,
    required int userId,
    required int orderId,
  }) {
    return switch (action) {
      .accept => orders.assign(carrierId: userId, orderId: orderId),
      .drop => orders.unassign(carrierId: userId, orderId: orderId),
      .pickup => orders.pickup(carrierId: userId, orderId: orderId),
      .transit => orders.transit(carrierId: userId, orderId: orderId),
      .deliver => orders.deliver(carrierId: userId, orderId: orderId),
      .cancel => orders.cancel(userId: userId, orderId: orderId),
    };
  }
}

final class ExtendParcelOrderUseCase {
  ExtendParcelOrderUseCase(this.orders);

  final ParcelOrderRepository orders;

  Future<Result<ParcelOrder, BusinessFailure>> call({
    required int userId,
    required int orderId,
    required DateTime neededBefore,
  }) {
    return orders.extend(
      userId: userId,
      orderId: orderId,
      neededBefore: neededBefore,
    );
  }
}
