import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

import '../../core/base/result.dart';
import '../../core/config/app_config.dart';
import '../../domain/entities/geo.dart';
import '../../domain/failures/business_failure.dart';
import '../../domain/repositories/location_repository.dart';
import '../base/repository.dart';
import '../mappers/json_mappers.dart';
import '../services/cache/cache_service.dart';
import '../services/network/exceptions.dart';
import '../services/network/rest_client.dart';

/// Geolocator for the fix, the platform geocoder first (free, offline
/// capable) and Google's REST geocoder as the fallback, Google Places for
/// search — the same providers the Ionic app used.
final class LocationRepositoryImpl extends Repository
    implements LocationRepository {
  LocationRepositoryImpl({
    required this.remote,
    required this.local,
    required super.crashReporter,
  });

  final RestClient remote;
  final CacheService local;

  static const _language = 'en';

  @override
  GeoPoint? get lastKnown {
    final lat = local.get<double>(CacheKey.currentLat);
    final lng = local.get<double>(CacheKey.currentLng);
    if (lat == null || lng == null) return null;
    return GeoPoint(lat, lng);
  }

  @override
  Future<Result<GeoPoint, BusinessFailure>> currentPosition() {
    return asyncGuard(() async {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const ApiResponseException('Location services are disabled');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const ApiResponseException('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final point = GeoPoint(position.latitude, position.longitude);
      await local.save(CacheKey.currentLat, point.lat);
      await local.save(CacheKey.currentLng, point.lng);
      return point;
    });
  }

  @override
  Future<Result<PlaceInfo, BusinessFailure>> reverseGeocode(GeoPoint point) {
    return asyncGuard(() async {
      try {
        final marks = await geocoding.placemarkFromCoordinates(
          point.lat,
          point.lng,
        );
        if (marks.isNotEmpty) {
          final m = marks.first;
          final city = _firstNonEmpty([
            m.locality,
            m.subAdministrativeArea,
            m.administrativeArea,
            m.subLocality,
          ]);
          final formatted = _firstNonEmpty([
            [
              m.street,
              m.locality,
              m.country,
            ].where((p) => p != null && p.isNotEmpty).join(', '),
          ]);
          return PlaceInfo(
            formatted: formatted ?? city ?? m.country ?? '',
            city: city,
            country: m.country,
            point: point,
          );
        }
      } on Object {
        // Fall through to Google.
      }
      return _googleReverse(point);
    });
  }

  Future<PlaceInfo> _googleReverse(GeoPoint point) async {
    final response = await remote.geocode(
      '${point.lat},${point.lng}',
      AppConfig.googleMapsApiKey,
      _language,
    );
    final body = Json.asMap(response.data);
    final results = Json.asList(body['results']);
    if (results.isEmpty) {
      throw const ApiResponseException('Address not found');
    }
    return _placeFromGoogle(results.first, point);
  }

  PlaceInfo _placeFromGoogle(Map<String, dynamic> result, GeoPoint? point) {
    String? city;
    String? country;
    for (final component in Json.asList(result['address_components'])) {
      final types = (component['types'] as List?)?.cast<String>() ?? const [];
      final name = Json.toStr(component['long_name']);
      if (types.contains('locality')) city ??= name;
      if (types.contains('administrative_area_level_1')) city ??= name;
      if (types.contains('country')) country = name;
    }
    final geometry = result['geometry'];
    GeoPoint? resolved = point;
    if (geometry is Map && geometry['location'] is Map) {
      final loc = (geometry['location'] as Map).cast<String, dynamic>();
      final lat = Json.toDouble(loc['lat']);
      final lng = Json.toDouble(loc['lng']);
      if (lat != null && lng != null) resolved = GeoPoint(lat, lng);
    }
    return PlaceInfo(
      formatted: Json.str(result['formatted_address']),
      city: city,
      country: country,
      point: resolved,
    );
  }

  @override
  Future<Result<List<PlaceSuggestion>, BusinessFailure>> suggestions(
    String query,
  ) {
    return asyncGuard(() async {
      if (query.trim().isEmpty) return const [];
      final response = await remote.placesAutocomplete(
        query,
        AppConfig.googleMapsApiKey,
        _language,
      );
      final body = Json.asMap(response.data);
      return Json.asList(body['predictions'])
          .map(
            (p) => PlaceSuggestion(
              placeId: Json.str(p['place_id']),
              description: Json.str(p['description']),
            ),
          )
          .toList();
    });
  }

  @override
  Future<Result<PlaceInfo, BusinessFailure>> placeDetails(String placeId) {
    return asyncGuard(() async {
      final response = await remote.placeDetails(
        placeId,
        AppConfig.googleMapsApiKey,
        _language,
        'geometry,formatted_address,address_component',
      );
      final body = Json.asMap(response.data);
      final result = body['result'];
      if (result is! Map) throw const ApiResponseException('Place not found');
      return _placeFromGoogle(result.cast<String, dynamic>(), null);
    });
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v;
    }
    return null;
  }
}
