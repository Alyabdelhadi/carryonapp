import 'app_secrets.dart';

/// Third-party keys the app ships with. The Google Maps key is restricted
/// to this app's bundle id and is also embedded in the native projects;
/// the Shufti credentials live in the git-ignored `app_secrets.dart`
/// (copy `app_secrets.example.dart` to create it).
abstract final class AppConfig {
  static const String appName = 'CarryOn';

  /// Google Maps Platform key used for the map view, Places autocomplete
  /// and reverse geocoding. Also referenced from the Android manifest and
  /// iOS `AppDelegate`.
  static const String googleMapsApiKey =
      'AIzaSyBE_4VtJYMqVKPEkR75wfiopt9c08WuHag';

  /// Shufti Pro identity verification (selfie + document match at signup).
  static const String shuftiClientId = AppSecrets.shuftiClientId;
  static const String shuftiSecretKey = AppSecrets.shuftiSecretKey;

  /// FCM topic every install subscribes to for broadcast pushes.
  static const String broadcastTopic = 'carryon';

  /// FCM per-user topic: `user_<id>`.
  static String userTopic(int userId) => 'user_$userId';

  /// Country pre-selected in phone-code pickers.
  static const String defaultCountryName = 'Lebanon';

  /// How often the home screen re-checks the store version.
  static const Duration updateCheckInterval = Duration(hours: 6);

  /// Minimum gap between two update prompts.
  static const Duration updateCheckCooldown = Duration(hours: 24);
}
