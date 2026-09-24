import 'catalog.dart';

/// How often a carrier travels a route. Wire values match the backend.
enum TripFrequency {
  oneTime('one_time', 'One-time trip'),
  daily('daily', 'Daily'),
  weekdays('weekdays', 'Weekdays'),
  weekends('weekends', 'Weekends');

  const TripFrequency(this.wire, this.englishLabel);

  final String wire;

  /// English name, for logs only; screens use `frequency.label(l10n)`.
  final String englishLabel;

  bool get isRecurring => this != oneTime;

  static TripFrequency fromWire(String? value) {
    for (final f in values) {
      if (f.wire == value) return f;
    }
    return oneTime;
  }
}

/// A city endpoint of a trip, with its country, as the trip endpoints
/// embed it.
class TripCity {
  const TripCity({
    required this.id,
    required this.name,
    this.nameAr,
    this.countryId,
    this.countryName,
    this.countryNameAr,
    this.image,
  });

  final int? id;
  final String name;
  final String? nameAr;
  final int? countryId;
  final String? countryName;
  final String? countryNameAr;
  final String? image;

  String nameFor(String languageCode) =>
      PlaceNames.pick(languageCode, name, nameAr);

  String? countryNameFor(String languageCode) =>
      PlaceNames.pickNullable(languageCode, countryName, countryNameAr);
}

/// A carrier's declared travel route.
class Trip {
  const Trip({
    required this.id,
    required this.carrierId,
    required this.frequency,
    required this.from,
    required this.to,
    this.date,
    this.destinationImage,
  });

  final int id;
  final int carrierId;
  final TripFrequency frequency;

  /// Only set for [TripFrequency.oneTime].
  final DateTime? date;
  final TripCity from;
  final TripCity to;
  final String? destinationImage;

  /// A one-time trip whose date already passed no longer matches orders.
  bool get isUpcoming {
    if (date == null) return true;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    return !date!.isBefore(day);
  }
}

/// Body for creating or updating a trip.
class TripInput {
  const TripInput({
    required this.cityFromId,
    required this.cityToId,
    required this.carrierId,
    required this.frequency,
    this.date,
  });

  final int cityFromId;
  final int cityToId;
  final int carrierId;
  final TripFrequency frequency;
  final DateTime? date;
}
