import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../core/logger/log.dart';
import '../request_auth.dart';
import 'token_store.dart';

/// In-memory cache over a [TokenStore] with single-flight refresh.
///
/// The constructor starts the store read; readers await it once, then
/// read from memory. Writes are write-through: memory updates *after* the
/// store does, so a failed write cannot leave memory ahead of disk.
/// Refresh is single-flight — concurrent callers share one HTTP roundtrip
/// via an inflight [Completer]; while a [refresh] is in progress, later
/// callers await its outcome.
///
/// Refresh uses the same transport [Dio] as ordinary requests. The
/// refresh call is *unmarked*, which defaults to `RequestAuth.public`, so
/// the auth-header interceptor skips it; this class sends the refresh
/// token itself (see [_performRefresh] for the backend contract).
class TokenManager {
  TokenManager({
    required this._store,
    required this._transport,
    required this._refreshEndpoint,
  }) {
    _ready = _load();
  }

  final TokenStore _store;
  final Dio _transport;
  final String _refreshEndpoint;

  late final Future<void> _ready;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  Completer<String>? _inflightRefresh;

  /// Refresh this long before the access token expires, so a request (and
  /// multipart uploads, which cannot be replayed after a 401) never goes
  /// out with a token that dies on the way.
  static const _expiryMargin = Duration(seconds: 60);

  /// Called once when the server rejected the refresh token: the session
  /// is over (logged out elsewhere, password changed, token stolen).
  void Function()? onSessionExpired;

  Future<String?> get accessToken async {
    await _ready;
    return _accessToken;
  }

  /// The access token to send now, refreshed first when it is about to
  /// expire. Falls back to the current token when the refresh fails for a
  /// transient reason (the server then answers 401 and the retry path runs).
  Future<String?> validAccessToken() async {
    await _ready;
    final expiresAt = _expiresAt;
    final refresh = _refreshToken;
    if (expiresAt != null &&
        refresh != null &&
        refresh.isNotEmpty &&
        DateTime.now().add(_expiryMargin).isAfter(expiresAt)) {
      try {
        return await this.refresh();
      } catch (_) {
        return _accessToken;
      }
    }
    return _accessToken;
  }

  Future<String?> get refreshToken async {
    await _ready;
    return _refreshToken;
  }

  /// Stores [access] (and optionally [refresh]) in memory and the underlying
  /// store. Call after a successful login or signup response.
  ///
  /// Unlike reads (which swallow store errors and return null), a store
  /// *write* failure propagates by design: memory only updates after the
  /// store does, so a keystore failure surfaces as a failed login instead
  /// of a session that silently disappears on the next launch.
  Future<void> persist({
    required String access,
    String? refresh,
    Duration? expiresIn,
  }) async {
    await _ready;
    await _store.write(.access, access);
    _accessToken = access;
    if (refresh != null) {
      await _store.write(.refresh, refresh);
      _refreshToken = refresh;
    }
    await _writeExpiry(expiresIn);
  }

  Future<void> _writeExpiry(Duration? expiresIn) async {
    if (expiresIn == null) {
      await _store.delete(.expiresAt);
      _expiresAt = null;
      return;
    }
    final at = DateTime.now().add(expiresIn);
    await _store.write(.expiresAt, '${at.millisecondsSinceEpoch}');
    _expiresAt = at;
  }

  /// Refreshes the access token. Concurrent callers share one HTTP roundtrip.
  ///
  /// On success the new access token is persisted and returned. On failure
  /// the underlying error rethrows — but what happens to the stored tokens
  /// depends on *why* the refresh failed:
  ///
  /// - **Auth-definitive** — the server rejected the refresh token (400/401/
  ///   403), the success response was malformed, or no refresh token exists.
  ///   The session is over; both tokens are [clear]ed.
  /// - **Transient** — timeout, connection error, 5xx, or any other fault
  ///   that proves nothing about the token's validity. Tokens are *kept*:
  ///   a momentary network failure or a refresh-endpoint outage must not
  ///   log the user out. The failed request still surfaces its original
  ///   error, and the next 401 triggers a fresh attempt.
  Future<String> refresh() async {
    await _ready;

    final existing = _inflightRefresh;
    if (existing != null) return existing.future;

    final completer = Completer<String>();
    _inflightRefresh = completer;
    unawaited(_runRefresh(completer));
    return completer.future;
  }

  Future<void> _runRefresh(Completer<String> completer) async {
    try {
      final newAccess = await _performRefresh();
      completer.complete(newAccess);
    } catch (e, stackTrace) {
      if (_isAuthDefinitive(e)) {
        final hadSession = _refreshToken != null;
        try {
          await clear();
        } catch (clearError, clearStack) {
          Log.error('TokenManager.clear failed: $clearError\n$clearStack');
        }
        if (hadSession) onSessionExpired?.call();
      }
      completer.completeError(e, stackTrace);
    } finally {
      _inflightRefresh = null;
    }
  }

  /// Whether a refresh failure proves the session is over. Clearing tokens
  /// is destructive, so the default is to keep them: only an explicit
  /// rejection of the refresh token (400/401/403) or a [StateError] from
  /// [_performRefresh] (no refresh token, malformed success response)
  /// qualifies. Timeouts, connection errors, and 5xx are transient.
  bool _isAuthDefinitive(Object error) {
    if (error is StateError) return true;
    if (error is DioException && error.type == DioExceptionType.badResponse) {
      return switch (error.response?.statusCode) {
        400 || 401 || 403 => true,
        _ => false,
      };
    }

    return false;
  }

  /// Empties memory and the underlying store.
  Future<void> clear() async {
    await _ready;
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    await _store.clear();
  }

  Future<void> _load() async {
    try {
      _accessToken = await _store.read(.access);
      _refreshToken = await _store.read(.refresh);
      final millis = int.tryParse(await _store.read(.expiresAt) ?? '');
      _expiresAt = millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (e, stackTrace) {
      Log.error('TokenManager._load failed: $e\n$stackTrace');
    }
  }

  Future<String> _performRefresh() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No refresh token available');
    }

    // explicitly public: the refresh call must never carry (or try to
    // refresh) an access token itself
    final response = await _transport.post<dynamic>(
      _refreshEndpoint,
      data: {'refreshToken': refreshToken},
      options: Options(extra: {requestAuthKey: RequestAuth.public}),
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('Refresh response was not a JSON object');
    }

    final newAccess = data['accessToken'];
    if (newAccess is! String || newAccess.isEmpty) {
      throw StateError('Refresh response missing accessToken');
    }

    await _store.write(.access, newAccess);
    _accessToken = newAccess;

    final newRefresh = data['refreshToken'];
    if (newRefresh is String && newRefresh.isNotEmpty) {
      await _store.write(.refresh, newRefresh);
      _refreshToken = newRefresh;
    }

    final expiresIn = data['expiresIn'];
    await _writeExpiry(
      expiresIn is num ? Duration(seconds: expiresIn.toInt()) : null,
    );

    return newAccess;
  }
}
