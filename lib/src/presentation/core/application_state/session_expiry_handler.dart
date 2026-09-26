import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/dependency_injection.dart';
import 'session_status_provider/session_status_provider.dart';

/// Signs the app out when the backend ends the session: the refresh token
/// was rejected (logged out on another device, password changed, token
/// reused). Also drops a session saved by a build without tokens, which
/// could no longer call the API.
void attachSessionExpiryHandler(ProviderContainer container) {
  final tokens = container.read(tokenManagerProvider);

  // The session store sits on SharedPreferences, which loads during
  // startup; it is only read once that is done.
  Future<void> signOut() async {
    await container.read(sharedPreferencesProvider.future);
    await container.read(sessionRepositoryProvider).clearSession();
    container.invalidate(sessionStatusProvider);
  }

  tokens.onSessionExpired = () => unawaited(signOut());

  unawaited(() async {
    await container.read(sharedPreferencesProvider.future);
    final session = container.read(sessionRepositoryProvider);
    if (session.isLoggedIn && await tokens.refreshToken == null) {
      await signOut();
    }
  }());
}
