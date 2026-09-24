abstract class RouterRepository {
  /// Whether a session exists. Derived from the stored user id — the
  /// source of truth for this token-less backend.
  Future<bool> hasSession();
}
