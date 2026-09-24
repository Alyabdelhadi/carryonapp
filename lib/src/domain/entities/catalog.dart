// Admin-managed reference data the app renders.

class Country {
  const Country({
    required this.id,
    required this.name,
    this.code,
    this.phoneCode,
    this.flag,
    this.nameAr,
  });

  final int id;
  final String name;
  final String? code;

  /// E.g. `+961`.
  final String? phoneCode;

  /// Emoji flag.
  final String? flag;

  /// Admin/seeded Arabic name; null when not provided.
  final String? nameAr;

  /// The name for [languageCode]: Arabic when available, else English.
  String nameFor(String languageCode) =>
      PlaceNames.pick(languageCode, name, nameAr);

  /// True when [query] matches the English or Arabic name.
  bool matches(String query) => PlaceNames.matches(query, name, nameAr);
}

class City {
  const City({
    required this.id,
    required this.name,
    required this.countryId,
    this.image,
    this.nameAr,
  });

  final int id;
  final String name;
  final int countryId;
  final String? image;

  /// Arabic name (admin-entered or machine-translated); null when unknown.
  final String? nameAr;

  String nameFor(String languageCode) =>
      PlaceNames.pick(languageCode, name, nameAr);

  bool matches(String query) => PlaceNames.matches(query, name, nameAr);
}

/// Shared rule for every place name that has an optional Arabic form.
abstract final class PlaceNames {
  static String pick(String languageCode, String name, String? nameAr) {
    if (languageCode == 'ar' && nameAr != null && nameAr.trim().isNotEmpty) {
      return nameAr;
    }
    return name;
  }

  static String? pickNullable(
    String languageCode,
    String? name,
    String? nameAr,
  ) {
    if (name == null) return null;
    return pick(languageCode, name, nameAr);
  }

  static bool matches(String query, String name, String? nameAr) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    return nameAr != null && nameAr.toLowerCase().contains(q);
  }
}

/// Package type (Document, Gift, Electronic, ...). `text` is the hint the
/// admin attached ("Passports are not allowed").
class ParcelCategory {
  const ParcelCategory({
    required this.id,
    required this.name,
    this.text,
    this.image,
    this.sortNo = 0,
    this.nameAr,
  });

  final int id;
  final String name;
  final String? text;

  /// File name under `upload/categories/`.
  final String? image;
  final int sortNo;

  /// Admin-entered Arabic name; null when not provided.
  final String? nameAr;

  String nameFor(String languageCode) =>
      PlaceNames.pick(languageCode, name, nameAr);
}

/// One of the three home actions: send, receive, carry.
class AppService {
  const AppService({
    required this.id,
    required this.name,
    this.nameAr,
    this.image,
    this.sortNo = 0,
  });

  final int id;
  final String name;

  /// Admin-entered Arabic name; null or empty when not provided.
  final String? nameAr;

  /// The name for [languageCode]: Arabic when available, else English.
  String nameFor(String languageCode) {
    final ar = nameAr;
    if (languageCode == 'ar' && ar != null && ar.trim().isNotEmpty) return ar;
    return name;
  }

  /// File name under `upload/services/`.
  final String? image;
  final int sortNo;
}

/// A promotional banner image.
class SliderImage {
  const SliderImage({
    required this.id,
    required this.image,
    this.imageAr,
    this.sortNo = 0,
  });

  final int id;

  /// File name under `upload/sliders/`.
  final String image;

  /// Optional Arabic version of the banner, same folder.
  final String? imageAr;
  final int sortNo;

  String imageFor(String languageCode) =>
      PlaceNames.pick(languageCode, image, imageAr);
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.code,
    required this.currency,
    this.publishableKey,
  });

  final int id;
  final String name;

  /// `cash_on_delivery`, `stripe`, ...
  final String code;
  final String currency;
  final String? publishableKey;

  bool get isCash => code == 'cash_on_delivery';
}

/// Minimum store versions the backend advertises for the update prompt.
class AppVersionInfo {
  const AppVersionInfo({this.android, this.ios});

  final String? android;
  final String? ios;
}

/// Admin-managed runtime switches (`/appSettings`).
class AppSettings {
  const AppSettings({this.shuftiEnabled = true});

  /// When false, signup skips the Shufti identity check and only uploads
  /// the photos for manual review.
  final bool shuftiEnabled;
}
