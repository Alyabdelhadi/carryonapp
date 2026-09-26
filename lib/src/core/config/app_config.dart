/// Third-party keys the app ships with. The Google Maps key is restricted
/// to this app's bundle id and is also embedded in the native projects.
/// Shufti Pro identity checks run on the backend; the app holds no keys.
abstract final class AppConfig {
  static const String appName = 'CarryOn';

  /// Google Maps Platform key used for the map view, Places autocomplete
  /// and reverse geocoding. Also referenced from the Android manifest and
  /// iOS `AppDelegate`.
  static const String googleMapsApiKey =
      'AIzaSyBE_4VtJYMqVKPEkR75wfiopt9c08WuHag';

  /// FCM topic every install subscribes to for broadcast pushes.
  static const String broadcastTopic = 'carryon';

  /// FCM per-user topic: `user_<id>`.
  static String userTopic(int userId) => 'user_$userId';

  /// Country pre-selected in phone-code pickers.
  static const String defaultCountryName = 'Lebanon';
}
