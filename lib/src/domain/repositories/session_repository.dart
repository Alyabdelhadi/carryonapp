import '../entities/app_texts.dart';
import '../entities/app_user.dart';

/// The signed-in state and the small preferences that travel with it. The
/// backend issues no tokens: a stored user id *is* the session.
abstract interface class SessionRepository {
  int? get userId;

  bool get isLoggedIn;

  /// The last user payload we stored; may be stale until `refreshUser`.
  AppUser? get user;

  Future<void> saveUser(AppUser user);

  Future<void> clearSession();

  bool get notificationsEnabled;

  Future<void> setNotificationsEnabled(bool enabled);

  AppTexts get cachedTexts;

  Future<void> cacheTexts(AppTexts texts);
}
