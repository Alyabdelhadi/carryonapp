enum CacheKey {
  /// The signed-in app user's id. Its presence *is* the session: the
  /// backend has no tokens, every request carries this id.
  userId,

  /// JSON of the last `userInfo` / login payload, for offline display.
  userData,

  /// The user's role as reported by `userInfo` (`carrier`).
  userRole,

  /// Push topics subscribed / opted out (account screen toggle).
  notificationsEnabled,

  /// JSON of the admin-managed UI copy (`getTexts`).
  appTexts,

  /// Epoch millis of the last store-version check.
  lastUpdateCheck,

  /// Epoch millis until which the user asked not to be reminded to update.
  updatePostponedUntil,

  /// Last known device coordinates, so screens can render before the GPS
  /// fix arrives.
  currentLat,
  currentLng,
  language,
}

/// Key-value persistence for small app state, keyed by [CacheKey] so
/// every stored name lives in one enum instead of scattered strings.
///
/// Values are primitives only ([String], [int], [bool], [double]);
/// implementations throw [ArgumentError] on anything else rather than
/// coercing. Anything richer belongs in a real store, not a preference
/// cache.
abstract class CacheService {
  Future<void> save<T>(CacheKey key, T value);

  T? get<T>(CacheKey key);

  Future<void> remove(List<CacheKey> keys);

  Future<void> clear();
}
