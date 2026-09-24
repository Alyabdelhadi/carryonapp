import 'dart:math' as math;

/// An airport the calculator knows, with its IATA [code] and coordinates.
class Airport {
  const Airport({
    required this.code,
    required this.name,
    required this.lat,
    required this.lon,
  });

  final String code;
  final String name;
  final double lat;
  final double lon;
}

/// What the calculator prints for a valid route and weight. Numbers keep
/// the precision the original screen showed (whole km, two decimals for
/// everything else).
class CarbonEstimate {
  const CarbonEstimate({
    required this.route,
    required this.distanceKm,
    required this.traditionalCo2Kg,
    required this.carryonCo2Kg,
    required this.co2SavedKg,
    required this.treesSaved,
    required this.cargoCost,
    required this.carryonCost,
    required this.youSave,
  });

  /// "BEY → DXB", wrapped in a left-to-right isolate (U+2066 … U+2069) so
  /// the codes keep their order inside right-to-left text.
  final String route;
  final int distanceKm;
  final double traditionalCo2Kg;
  final double carryonCo2Kg;
  final double co2SavedKg;
  final double treesSaved;
  final double cargoCost;
  final double carryonCost;
  final double youSave;
}

/// The CO₂ / cost calculator behind the "Carbon Calculator" screen — the
/// original `offer` page's formulas, unchanged, with no Flutter dependency
/// so it can be unit-tested on its own.
abstract final class CarbonCalculator {
  /// Mean Earth radius, km.
  static const double earthRadiusKm = 6371;

  /// kg CO₂ per kg of cargo per km flown by traditional freight.
  static const double emissionFactor = 0.0006;

  /// kg CO₂ one tree absorbs — the conversion the original used.
  static const double co2PerTreeKg = 21;

  /// USD per kg per km for cargo and for CarryOn.
  static const double cargoRatePerKgPerKm = 0.03;
  static const double carryonRatePerKgPerKm = 0.01;

  /// Preset weights (kg) offered before "Other".
  static const List<double> presetWeightsKg = [0.5, 1, 2, 3, 5, 7, 10, 15, 23];

  /// The airport list as the original shipped it, minus its duplicate
  /// rows (DEL, LGW, DUB and MUC appeared twice; the first entry always
  /// won the lookup, so dropping the repeats changes nothing).
  static const List<Airport> airports = [
    Airport(code: 'BEY', name: 'Beirut (BEY)', lat: 33.8209, lon: 35.4884),
    Airport(code: 'DXB', name: 'Dubai (DXB)', lat: 25.2532, lon: 55.3657),
    Airport(code: 'AMM', name: 'Amman (AMM)', lat: 31.7226, lon: 35.9932),
    Airport(code: 'CAI', name: 'Cairo (CAI)', lat: 30.1120, lon: 31.4000),
    Airport(code: 'RUH', name: 'Riyadh (RUH)', lat: 24.9576, lon: 46.6988),
    Airport(code: 'JED', name: 'Jeddah (JED)', lat: 21.6702, lon: 39.1526),
    Airport(code: 'DOH', name: 'Doha (DOH)', lat: 25.2736, lon: 51.6080),
    Airport(code: 'CDG', name: 'Paris (CDG)', lat: 49.0097, lon: 2.5479),
    Airport(code: 'LHR', name: 'London (LHR)', lat: 51.4700, lon: -0.4543),
    Airport(code: 'FRA', name: 'Frankfurt (FRA)', lat: 50.0379, lon: 8.5622),
    Airport(code: 'ATH', name: 'Athens (ATH)', lat: 37.9364, lon: 23.9475),
    Airport(code: 'IST', name: 'Istanbul (IST)', lat: 40.9769, lon: 28.8146),
    Airport(code: 'MUC', name: 'Munich (MUC)', lat: 48.3538, lon: 11.7861),
    Airport(code: 'AMS', name: 'Amsterdam (AMS)', lat: 52.3105, lon: 4.7683),
    Airport(
      code: 'JFK',
      name: 'New York JFK (JFK)',
      lat: 40.6413,
      lon: -73.7781,
    ),
    Airport(
      code: 'SFO',
      name: 'San Francisco (SFO)',
      lat: 37.6213,
      lon: -122.3790,
    ),
    Airport(code: 'SIN', name: 'Singapore (SIN)', lat: 1.3644, lon: 103.9915),
    Airport(
      code: 'HND',
      name: 'Tokyo Haneda (HND)',
      lat: 35.5494,
      lon: 139.7798,
    ),
    Airport(code: 'SYD', name: 'Sydney (SYD)', lat: -33.9399, lon: 151.1753),
    Airport(
      code: 'GRU',
      name: 'São Paulo Guarulhos (GRU)',
      lat: -23.4356,
      lon: -46.4731,
    ),
    Airport(
      code: 'LAX',
      name: 'Los Angeles (LAX)',
      lat: 33.9416,
      lon: -118.4085,
    ),
    Airport(
      code: 'ORD',
      name: "Chicago O'Hare (ORD)",
      lat: 41.9742,
      lon: -87.9073,
    ),
    Airport(
      code: 'YYZ',
      name: 'Toronto Pearson (YYZ)',
      lat: 43.6777,
      lon: -79.6248,
    ),
    Airport(
      code: 'MEX',
      name: 'Mexico City (MEX)',
      lat: 19.4361,
      lon: -99.0719,
    ),
    Airport(code: 'DEL', name: 'Delhi (DEL)', lat: 28.5562, lon: 77.1000),
    Airport(code: 'BOM', name: 'Mumbai (BOM)', lat: 19.0896, lon: 72.8656),
    Airport(
      code: 'KUL',
      name: 'Kuala Lumpur (KUL)',
      lat: 2.7456,
      lon: 101.7092,
    ),
    Airport(code: 'MEL', name: 'Melbourne (MEL)', lat: -37.6690, lon: 144.8410),
    Airport(code: 'CPT', name: 'Cape Town (CPT)', lat: -33.9695, lon: 18.5972),
    Airport(
      code: 'ICN',
      name: 'Seoul Incheon (ICN)',
      lat: 37.4602,
      lon: 126.4407,
    ),
    Airport(code: 'DUB', name: 'Dublin (DUB)', lat: 53.4213, lon: -6.2701),
    Airport(code: 'VIE', name: 'Vienna (VIE)', lat: 48.1103, lon: 16.5697),
    Airport(code: 'ZRH', name: 'Zurich (ZRH)', lat: 47.4647, lon: 8.5492),
    Airport(
      code: 'MXP',
      name: 'Milan Malpensa (MXP)',
      lat: 45.6301,
      lon: 8.7281,
    ),
    Airport(code: 'CPH', name: 'Copenhagen (CPH)', lat: 55.6181, lon: 12.6560),
    Airport(
      code: 'OSL',
      name: 'Oslo Gardermoen (OSL)',
      lat: 60.1939,
      lon: 11.1004,
    ),
    Airport(
      code: 'SEA',
      name: 'Seattle-Tacoma (SEA)',
      lat: 47.4502,
      lon: -122.3088,
    ),
    Airport(
      code: 'BOS',
      name: 'Boston Logan (BOS)',
      lat: 42.3656,
      lon: -71.0096,
    ),
    Airport(code: 'MIA', name: 'Miami (MIA)', lat: 25.7959, lon: -80.2870),
    Airport(
      code: 'PHX',
      name: 'Phoenix Sky Harbor (PHX)',
      lat: 33.4342,
      lon: -112.0116,
    ),
    Airport(
      code: 'IAH',
      name: 'Houston Intercontinental (IAH)',
      lat: 29.9902,
      lon: -95.3368,
    ),
    Airport(
      code: 'ATL',
      name: 'Atlanta Hartsfield-Jackson (ATL)',
      lat: 33.6407,
      lon: -84.4277,
    ),
    Airport(
      code: 'LGW',
      name: 'London Gatwick (LGW)',
      lat: 51.1537,
      lon: -0.1821,
    ),
    Airport(
      code: 'NRT',
      name: 'Tokyo Narita (NRT)',
      lat: 35.7767,
      lon: 140.3189,
    ),
    Airport(
      code: 'BKK',
      name: 'Bangkok Suvarnabhumi (BKK)',
      lat: 13.6900,
      lon: 100.7501,
    ),
    Airport(
      code: 'SVO',
      name: 'Moscow Sheremetyevo (SVO)',
      lat: 55.9726,
      lon: 37.4146,
    ),
    Airport(code: 'YVR', name: 'Vancouver (YVR)', lat: 49.1951, lon: -123.1779),
    Airport(code: 'HEL', name: 'Helsinki (HEL)', lat: 60.3172, lon: 24.9633),
    Airport(code: 'BRU', name: 'Brussels (BRU)', lat: 50.9010, lon: 4.4844),
  ];

  static Airport? airportByCode(String? code) {
    if (code == null) return null;
    for (final a in airports) {
      if (a.code == code) return a;
    }
    return null;
  }

  /// Best-effort match of a free-text city name ("Dubai", "dubai (DXB)")
  /// to an airport, for pre-filling from an order.
  static Airport? airportForCity(String? city) {
    final q = (city ?? '').trim().toLowerCase();
    if (q.isEmpty) return null;
    for (final a in airports) {
      if (a.code.toLowerCase() == q) return a;
    }
    for (final a in airports) {
      final name = a.name.toLowerCase();
      if (name.startsWith(q) ||
          name.contains(q) ||
          q.contains(a.code.toLowerCase())) {
        return a;
      }
    }
    return null;
  }

  /// Great-circle distance in km (haversine).
  static double distanceKm(Airport from, Airport to) {
    double toRad(double deg) => deg * math.pi / 180;

    final dLat = toRad(to.lat - from.lat);
    final dLon = toRad(to.lon - from.lon);
    final lat1 = toRad(from.lat);
    final lat2 = toRad(to.lat);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Null when the inputs are unusable: a missing airport, the same
  /// airport twice, or a non-positive weight. The screen then shows its
  /// invalid-input message.
  static CarbonEstimate? estimate({
    required Airport? from,
    required Airport? to,
    required double? weightKg,
  }) {
    if (from == null || to == null || from.code == to.code) return null;
    if (weightKg == null || weightKg.isNaN || weightKg <= 0) return null;

    final distance = distanceKm(from, to);
    final traditionalCo2 = weightKg * distance * emissionFactor;
    const carryonCo2 = 0.0; // CarryOn rides on a trip already being made.
    final co2Saved = traditionalCo2 - carryonCo2;
    final treesSaved = co2Saved / co2PerTreeKg;

    final cargoCost = weightKg * distance * cargoRatePerKgPerKm;
    final carryonCost = weightKg * distance * carryonRatePerKgPerKm;
    final youSave = cargoCost - carryonCost;

    return CarbonEstimate(
      route: '\u2066${from.code} → ${to.code}\u2069',
      distanceKm: distance.round(),
      traditionalCo2Kg: traditionalCo2,
      carryonCo2Kg: carryonCo2,
      co2SavedKg: co2Saved,
      treesSaved: treesSaved,
      cargoCost: cargoCost,
      carryonCost: carryonCost,
      youSave: youSave,
    );
  }
}
