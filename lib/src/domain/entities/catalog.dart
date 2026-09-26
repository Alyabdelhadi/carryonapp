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
  const AppSettings({
    this.shuftiEnabled = true,
    this.shuftiLive = false,
    this.payments = const PaymentRules(),
  });

  /// When false, signup skips the Shufti identity check and only uploads
  /// the photos for manual review.
  final bool shuftiEnabled;

  /// With [shuftiEnabled]: verification happens live on Shufti's own page
  /// (selfie with liveness check + ID scan) instead of uploaded photos,
  /// and signup asks for no ID document.
  final bool shuftiLive;

  final PaymentRules payments;
}

/// One way a carrier can be paid out (admin-edited list).
class PayoutMethod {
  const PayoutMethod({required this.code, required this.name});

  final String code;
  final String name;
}

/// The card-payment and wallet rules from the admin App Settings page
/// (`payments` block of `/appSettings`).
class PaymentRules {
  const PaymentRules({
    this.onlinePaymentEnabled = false,
    this.currency = 'USD',
    this.commissionPercent = 15,
    this.payoutMinimum = 20,
    this.payoutHoldDays = 3,
    this.paymentDeadlineHours = 24,
    this.payoutMethods = const [],
  });

  /// Stripe is enabled and configured on the backend.
  final bool onlinePaymentEnabled;
  final String currency;

  /// Percentage of the reward CarryOn keeps on card orders.
  final double commissionPercent;
  final double payoutMinimum;
  final int payoutHoldDays;
  final int paymentDeadlineHours;
  final List<PayoutMethod> payoutMethods;

  /// The carrier's share of a numeric reward.
  double carrierShare(double reward) =>
      (reward - reward * commissionPercent / 100).clamp(0, double.infinity);
}

/// The counters on the home screen (`/stats`): computed by the backend or
/// fixed by the admin on the App Settings page.
class HomeStats {
  const HomeStats({
    required this.packages,
    required this.users,
    required this.treesSaved,
    required this.cities,
  });

  final int packages;
  final int users;
  final int treesSaved;
  final int cities;
}

/// The admin-edited quick picks: weights (kg) for the order form and the
/// carbon calculator (`/weights`), and reward amounts for the order form
/// (`/tips`, 0 = Free). [defaults] are the values the app shipped with.
class QuickPicks {
  const QuickPicks({
    required this.orderWeightsKg,
    required this.calculatorWeightsKg,
    required this.rewards,
  });

  final List<double> orderWeightsKg;
  final List<double> calculatorWeightsKg;

  /// Reward amounts in the payment currency; 0 is "Free".
  final List<double> rewards;

  static const defaults = QuickPicks(
    orderWeightsKg: [0.5, 1, 2, 5, 10, 20],
    calculatorWeightsKg: [0.5, 1, 2, 3, 5, 7, 10, 15, 23],
    rewards: [0, 10, 20, 50, 100, 150, 200],
  );

  /// "0.5", "2" — how a quick pick reads on a chip and on the wire.
  static String format(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.contains('.')
        ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
        : fixed;
  }
}
