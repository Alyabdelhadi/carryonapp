import 'catalog.dart';

/// A saved address in the user's address book. `type` records where it was
/// captured: 1 when saved from the address book or the sender side of an
/// order (the Ionic address page always posted 1), 2 from the receiver side.
class Address {
  const Address({
    required this.id,
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
    this.city,
    this.street = '',
    this.building = '',
    this.apartment = '',
    this.notes,
    this.type = 0,
    this.cityAr,
    this.countryAr,
  });

  final int id;
  final String name;
  final String? city;
  final String country;

  /// Arabic forms resolved by the backend; null when unknown.
  final String? cityAr;
  final String? countryAr;

  String? cityFor(String languageCode) =>
      PlaceNames.pickNullable(languageCode, city, cityAr);

  String countryFor(String languageCode) =>
      PlaceNames.pick(languageCode, country, countryAr);

  /// [summary] in the given language.
  String summaryFor(String languageCode) {
    final parts = [
      street,
      building,
      apartment,
      cityFor(languageCode),
      countryFor(languageCode),
    ].where((p) => p != null && p.trim().isNotEmpty).cast<String>().toList();
    return parts.join(', ');
  }

  final double lat;
  final double lng;
  final String street;
  final String building;
  final String apartment;
  final String? notes;
  final int type;

  String get summary {
    final parts = [
      street,
      building,
      apartment,
      city,
      country,
    ].where((p) => p != null && p.trim().isNotEmpty).cast<String>().toList();
    return parts.join(', ');
  }
}

/// Body for creating or updating a saved address.
class AddressInput {
  const AddressInput({
    required this.userId,
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
    this.city,
    this.street = '',
    this.building = '',
    this.apartment = '',
    this.notes,
    this.type = 0,
  });

  final int userId;
  final String name;
  final String? city;
  final String country;
  final double lat;
  final double lng;
  final String street;
  final String building;
  final String apartment;
  final String? notes;
  final int type;
}
