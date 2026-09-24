import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../../domain/entities/trip.dart';
import '../../domain/failures/business_failure.dart';
import '../../domain/repositories/trip_repository.dart';
import '../base/repository.dart';
import '../mappers/json_mappers.dart';
import '../services/network/exceptions.dart';
import '../services/network/rest_client.dart';

final class TripRepositoryImpl extends Repository implements TripRepository {
  TripRepositoryImpl({required this.remote, required super.crashReporter});

  final RestClient remote;

  /// Create / update answer with the bare row (no city objects). Fetch the
  /// expanded trip so callers always get the same shape.
  Future<Trip> _expanded(Object? body) async {
    final map = Json.asMap(body);
    final id = Json.toInt(map['id']) ?? Json.toInt(map['trip_id']);
    if (id == null) throw const ApiResponseException('trip_not_saved');
    final response = await remote.tripById(id);
    if (response.data == null) {
      throw const ApiResponseException('Trip not found');
    }
    return TripMapper.fromJson(Json.asMap(response.data));
  }

  @override
  Future<Result<Trip, BusinessFailure>> create(TripInput input) {
    return asyncGuard(() async {
      final response = await remote.createTrip(TripMapper.inputToJson(input));
      return _expanded(response.data);
    });
  }

  @override
  Future<Result<Trip, BusinessFailure>> update(int id, TripInput input) {
    return asyncGuard(() async {
      final response = await remote.updateTrip(
        id,
        TripMapper.inputToJson(input),
      );
      if (response.data == null) {
        throw const ApiResponseException('Trip not found');
      }
      return _expanded(response.data);
    });
  }

  @override
  Future<Result<Unit, BusinessFailure>> delete(int id) {
    return asyncGuard(() async {
      final response = await remote.deleteTrip(id);
      final body = Json.asMap(response.data);
      if (!Json.toBool(body['success'])) {
        throw const ApiResponseException('Trip could not be deleted');
      }
      return Unit.value;
    });
  }

  @override
  Future<Result<Trip, BusinessFailure>> byId(int id) {
    return asyncGuard(() async {
      final response = await remote.tripById(id);
      if (response.data == null) {
        throw const ApiResponseException('Trip not found');
      }
      return TripMapper.fromJson(Json.asMap(response.data));
    });
  }

  @override
  Future<Result<List<Trip>, BusinessFailure>> byCarrier(int carrierId) {
    return asyncGuard(() async {
      final response = await remote.tripsByCarrier(carrierId);
      return Json.asList(response.data).map(TripMapper.fromJson).toList();
    });
  }
}
