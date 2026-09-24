import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../entities/trip.dart';
import '../failures/business_failure.dart';
import '../repositories/trip_repository.dart';

final class GetMyTripsUseCase {
  GetMyTripsUseCase(this.trips);

  final TripRepository trips;

  Future<Result<List<Trip>, BusinessFailure>> call(int carrierId) =>
      trips.byCarrier(carrierId);
}

final class SaveTripUseCase {
  SaveTripUseCase(this.trips);

  final TripRepository trips;

  Future<Result<Trip, BusinessFailure>> call(TripInput input, {int? tripId}) {
    return tripId == null ? trips.create(input) : trips.update(tripId, input);
  }
}

final class DeleteTripUseCase {
  DeleteTripUseCase(this.trips);

  final TripRepository trips;

  Future<Result<Unit, BusinessFailure>> call(int tripId) =>
      trips.delete(tripId);
}
