/// A coordinate pair.
class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;
}

/// What reverse geocoding tells us about a point.
class PlaceInfo {
  const PlaceInfo({
    required this.formatted,
    this.city,
    this.country,
    this.point,
  });

  /// Human readable line ("Verdun, Beirut, Lebanon").
  final String formatted;
  final String? city;
  final String? country;
  final GeoPoint? point;

  /// The short label the home header shows: city, else country, else the
  /// formatted line.
  String get shortLabel {
    if (city != null && city!.trim().isNotEmpty) return city!;
    if (country != null && country!.trim().isNotEmpty) return country!;
    return formatted;
  }
}

/// One row of a Places autocomplete result.
class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.description});

  final String placeId;
  final String description;
}
