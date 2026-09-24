import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/app_user.dart';

part 'session_status_provider.g.dart';

enum SessionStatus { authenticated, unauthenticated }

/// Whether a session exists, derived from the stored user id. Login,
/// signup, logout and account deletion invalidate this; the bottom tab bar
/// and the guarded screens react to it.
@Riverpod(keepAlive: true)
Future<SessionStatus> sessionStatus(Ref ref) async {
  final hasSession = await ref.read(getSessionStatusUseCaseProvider).call();

  return hasSession ? .authenticated : .unauthenticated;
}

/// The signed-in user's id, or null. Synchronous, for screens that need to
/// build a request.
@Riverpod(keepAlive: true)
int? currentUserId(Ref ref) {
  ref.watch(sessionStatusProvider);
  return ref.read(getSessionUseCaseProvider).userId;
}

/// The stored user (from the last login / `userInfo`). Screens that need
/// fresh stats call `fetchUserUseCase` and then invalidate this.
@Riverpod(keepAlive: true)
AppUser? currentUser(Ref ref) {
  ref.watch(sessionStatusProvider);
  return ref.read(getSessionUseCaseProvider).user;
}

/// True when the signed-in user has the carrier role.
@Riverpod(keepAlive: true)
bool isCarrier(Ref ref) => ref.watch(currentUserProvider)?.isCarrier ?? false;
