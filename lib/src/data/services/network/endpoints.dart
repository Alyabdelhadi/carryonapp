/// Every path the CarryOn backend exposes to the mobile app. The Laravel
/// API lives under `/admin/api`; uploaded media is served from
/// `/admin/upload/<kind>/<file>` (see [Endpoints.upload]).
///
/// Point a build at another backend (a local Laravel server, staging)
/// with `--dart-define=CARRYON_API_BASE=http://127.0.0.1:8000/api` and
/// `--dart-define=CARRYON_UPLOAD_BASE=http://127.0.0.1:8000/upload`.
class Endpoints {
  static const base = String.fromEnvironment(
    'CARRYON_API_BASE',
    defaultValue: 'https://carryon.app/admin/api',
  );

  /// Root for uploaded images: category icons, selfies, city photos.
  static const uploadBase = String.fromEnvironment(
    'CARRYON_UPLOAD_BASE',
    defaultValue: 'https://carryon.app/admin/upload',
  );

  static String upload(String kind, String file) => '$uploadBase/$kind/$file';

  static const String termsUrl = 'https://carryonapp.com/terms-conditions';
  static const String appStoreUrl = 'https://apps.apple.com/app/6624306639';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.CarryOnApp.App';

  // Auth / account
  static const String signup = '/signup';
  static const String login = '/login';
  static const String userInfo = '/userInfo';
  static const String updateInfo = '/updateInfo';
  static const String deleteUser = '/deleteUser';
  static const String sendResetLink = '/sendResetLink';
  static const String resetPassword = '/resetPassword';
  static const String rate = '/rate';

  // Catalog
  static const String services = '/services';
  static const String parcelCategories = '/parcelCategories';
  static const String sliders = '/sliders';
  static const String sliders2 = '/sliders2';
  static const String texts = '/getTexts';
  static const String appVersions = '/appVersions';
  static const String appSettings = '/appSettings';
  static const String countries = '/countries';
  static const String citiesByCountry = '/countries/{id}/cities';
  static const String paymentMethods = '/payment-methods';

  // Addresses
  static const String addresses = '/getAddresses';
  static const String createAddress = '/createAddress';
  static const String updateAddress = '/updateAddress';
  static const String deleteAddress = '/deleteAddress';

  // Parcel orders
  static const String createParcelOrder = '/createParcelOrder';
  static const String updateParcelOrder = '/updateParcelOrder';
  static const String assignParcelOrder = '/assignParcelOrder';
  static const String unassignParcelOrder = '/unassignParcelOrder';
  static const String pickupParcelOrder = '/pickupParcelOrder';
  static const String transitParcelOrder = '/transitParcelOrder';
  static const String deliverParcelOrder = '/deliverParcelOrder';
  static const String cancelParcelOrder = '/cancelParcelOrder';
  static const String extendParcelOrder = '/extendParcelOrder';
  static const String myCreatedParcelOrders = '/myCreatedParcelOrders';
  static const String myCarriedParcelOrders = '/myCarriedParcelOrders';
  static const String unassignedParcelOrders = '/unassginedParcelOrders';
  static const String matchingParcelOrders =
      '/carriers/{carrierId}/matching-parcel-orders';
  static const String markMatchingRead =
      '/carriers/{carrierId}/matching-parcel-orders/mark-read';

  // Trips
  static const String trips = '/trips';
  static const String tripById = '/trips/{id}';
  static const String tripsByCarrier = '/trips/carrier/{carrierId}';

  // Third party
  static const String shuftiVerify = 'https://api.shuftipro.com/';
  static const String googlePlacesAutocomplete =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String googlePlaceDetails =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const String googleGeocode =
      'https://maps.googleapis.com/maps/api/geocode/json';
}
