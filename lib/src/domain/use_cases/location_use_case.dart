import '../../core/base/result.dart';
import '../entities/geo.dart';
import '../failures/business_failure.dart';
import '../repositories/location_repository.dart';

final class GetCurrentPositionUseCase {
  GetCurrentPositionUseCase(this.location);

  final LocationRepository location;

  GeoPoint? get lastKnown => location.lastKnown;

  Future<Result<GeoPoint, BusinessFailure>> call() =>
      location.currentPosition();
}

/// Position + reverse geocode in one call, for the home header.
final class GetCurrentPlaceUseCase {
  GetCurrentPlaceUseCase(this.location);

  final LocationRepository location;

  Future<Result<PlaceInfo, BusinessFailure>> call() async {
    final position = await location.currentPosition();
    return switch (position) {
      Success(:final data) => location.reverseGeocode(data),
      Error(:final error) => Error(error),
    };
  }
}

final class ReverseGeocodeUseCase {
  ReverseGeocodeUseCase(this.location);

  final LocationRepository location;

  Future<Result<PlaceInfo, BusinessFailure>> call(GeoPoint point) =>
      location.reverseGeocode(point);
}

final class SearchPlacesUseCase {
  SearchPlacesUseCase(this.location);

  final LocationRepository location;

  Future<Result<List<PlaceSuggestion>, BusinessFailure>> call(String query) =>
      location.suggestions(query);

  Future<Result<PlaceInfo, BusinessFailure>> details(String placeId) =>
      location.placeDetails(placeId);
}
