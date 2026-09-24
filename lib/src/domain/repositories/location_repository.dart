import '../../core/base/result.dart';
import '../entities/geo.dart';
import '../failures/business_failure.dart';

/// Device location plus the Google geocoding / Places lookups the address
/// picker and home header rely on.
abstract interface class LocationRepository {
  /// Asks for permission if needed and returns the current fix.
  Future<Result<GeoPoint, BusinessFailure>> currentPosition();

  /// The last fix we cached, for instant rendering.
  GeoPoint? get lastKnown;

  Future<Result<PlaceInfo, BusinessFailure>> reverseGeocode(GeoPoint point);

  Future<Result<List<PlaceSuggestion>, BusinessFailure>> suggestions(
    String query,
  );

  Future<Result<PlaceInfo, BusinessFailure>> placeDetails(String placeId);
}
