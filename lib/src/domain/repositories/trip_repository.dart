import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../entities/trip.dart';
import '../failures/business_failure.dart';

abstract interface class TripRepository {
  Future<Result<Trip, BusinessFailure>> create(TripInput input);

  Future<Result<Trip, BusinessFailure>> update(int id, TripInput input);

  Future<Result<Unit, BusinessFailure>> delete(int id);

  Future<Result<Trip, BusinessFailure>> byId(int id);

  Future<Result<List<Trip>, BusinessFailure>> byCarrier(int carrierId);
}
