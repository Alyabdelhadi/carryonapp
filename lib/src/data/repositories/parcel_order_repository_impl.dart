import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../../domain/entities/parcel_order.dart';
import '../../domain/entities/parcel_order_draft.dart';
import '../../domain/entities/payment.dart';
import '../../domain/failures/business_failure.dart';
import '../../domain/repositories/parcel_order_repository.dart';
import '../base/repository.dart';
import '../failures/infra_failure.dart';
import '../mappers/json_mappers.dart';
import '../services/network/exceptions.dart';
import '../services/network/rest_client.dart';

final class ParcelOrderRepositoryImpl extends Repository
    implements ParcelOrderRepository {
  ParcelOrderRepositoryImpl({
    required this.remote,
    required super.crashReporter,
  });

  final RestClient remote;

  ParcelOrder _orderOf(Object? body) {
    final map = Json.requireDone(body);
    return ParcelOrderMapper.fromJson(Json.asMap(map['order']));
  }

  List<ParcelOrder> _listOf(Object? body) {
    return Json.asList(body).map(ParcelOrderMapper.fromJson).toList();
  }

  Map<String, dynamic> _action(int userId, int orderId) => {
    'user_id': userId,
    'order_id': orderId,
  };

  @override
  Future<Result<ParcelOrder, BusinessFailure>> create(ParcelOrderDraft draft) {
    return asyncGuard(() async {
      final response = await remote.createParcelOrder(
        ParcelOrderMapper.draftToJson(draft),
      );
      return _orderOf(response.data);
    });
  }

  @override
  Future<Result<ParcelOrder, BusinessFailure>> update(ParcelOrderDraft draft) {
    return asyncGuard(() async {
      final response = await remote.updateParcelOrder(
        ParcelOrderMapper.draftToJson(draft),
      );
      return _orderOf(response.data);
    });
  }

  @override
  Future<Result<List<ParcelOrder>, BusinessFailure>> myCreated(int userId) {
    return asyncGuard(() async {
      final response = await remote.myCreatedParcelOrders(userId);
      return _listOf(response.data);
    });
  }

  @override
  Future<Result<List<ParcelOrder>, BusinessFailure>> myCarried(int userId) {
    return asyncGuard(() async {
      final response = await remote.myCarriedParcelOrders(userId);
      return _listOf(response.data);
    });
  }

  @override
  Future<Result<List<ParcelOrder>, BusinessFailure>> unassigned() {
    return asyncGuard(() async {
      final response = await remote.unassignedParcelOrders();
      return _listOf(response.data);
    });
  }

  /// The backend answers 404 when the carrier has no trips; that is an
  /// empty list, not an error.
  @override
  Future<Result<List<ParcelOrder>, BusinessFailure>> matchingForCarrier(
    int carrierId,
  ) {
    return asyncGuard(
      () async {
        final response = await remote.matchingParcelOrders(carrierId);
        return _listOf(response.data);
      },
      recover: (failure) =>
          failure is NotFoundFailure ? const Success([]) : null,
    );
  }

  @override
  Future<Result<Unit, BusinessFailure>> markMatchingRead({
    required int carrierId,
    required int orderId,
  }) {
    return asyncGuard(() async {
      await remote.markMatchingRead(carrierId, {'order_id': orderId});
      return Unit.value;
    });
  }

  @override
  Future<Result<ParcelOrder, BusinessFailure>> byId(int orderId) {
    return asyncGuard(() async {
      final response = await remote.parcelOrderById(orderId);
      final body = response.data;
      if (body is! Map || body['id'] == null) {
        throw const ApiResponseException('Order not found');
      }
      return ParcelOrderMapper.fromJson(Json.asMap(body));
    });
  }

  @override
  Future<Result<StripePaymentIntent, BusinessFailure>> startStripePayment({
    required int userId,
    required int orderId,
  }) {
    return asyncGuard(() async {
      final response = await remote.stripeCreatePayment(
        _action(userId, orderId),
      );
      final map = Json.requireDone(response.data);
      return CatalogMapper.stripePaymentIntent(map);
    });
  }

  @override
  Future<Result<ParcelOrder, BusinessFailure>> syncStripePayment({
    required int userId,
    required int orderId,
  }) {
    return asyncGuard(() async {
      final response = await remote.stripeSyncPayment(_action(userId, orderId));
      return _orderOf(response.data);
    });
  }

  @override
  Future<Result<ParcelOrder, BusinessFailure>> assign({
    required int carrierId,
    required int orderId,
  }) {
    return asyncGuard(() async {
      final response = await remote.assignParcelOrder(
        _action(carrierId, orderId),
      );
      return _orderOf(response.data);
    });
  }

  @override
  Future<Result<ParcelOrder, BusinessFailure>> unassign({
    required int carrierId,
    required int orderId,
  }) {
    return asyncGuard(() async {
      final response = await remote.unassignParcelOrder(
        _action(carrierId, orderId),
      );
      return _orderOf(response.data);
    });
  }

  @override
  Future<Result<ParcelOrder, BusinessFailure>> pickup({
    required int carrierId,
    required int orderId,
  }) {
    return asyncGuard(() async {
      final response = await remote.pickupParcelOrder(
        _action(carrierId, orderId),
      );
      return _orderOf(response.data);
    });
  }

  @override
  Future<Result<ParcelOrder, BusinessFailure>> transit({
    required int carrierId,
    required int orderId,
  }) {
    return asyncGuard(() async {
      final response = await remote.transitParcelOrder(
        _action(carrierId, orderId),
      );
      return _orderOf(response.data);
    });
  }

  @override
  Future<Result<ParcelOrder, BusinessFailure>> deliver({
    required int carrierId,
    required int orderId,
  }) {
    return asyncGuard(() async {
      final response = await remote.deliverParcelOrder(
        _action(carrierId, orderId),
      );
      return _orderOf(response.data);
    });
  }

  @override
  Future<Result<ParcelOrder, BusinessFailure>> cancel({
    required int userId,
    required int orderId,
  }) {
    return asyncGuard(() async {
      final response = await remote.cancelParcelOrder(_action(userId, orderId));
      return _orderOf(response.data);
    });
  }

  @override
  Future<Result<ParcelOrder, BusinessFailure>> extend({
    required int userId,
    required int orderId,
    required DateTime neededBefore,
  }) {
    return asyncGuard(() async {
      final response = await remote.extendParcelOrder({
        ..._action(userId, orderId),
        'date_to': Json.dateOnly(neededBefore),
      });
      return _orderOf(response.data);
    });
  }
}
