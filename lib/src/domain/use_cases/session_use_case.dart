import '../entities/app_user.dart';
import '../repositories/session_repository.dart';

/// Synchronous reads of the signed-in state for widgets and providers.
final class GetSessionUseCase {
  GetSessionUseCase(this.session);

  final SessionRepository session;

  int? get userId => session.userId;

  bool get isLoggedIn => session.isLoggedIn;

  AppUser? get user => session.user;

  bool get notificationsEnabled => session.notificationsEnabled;
}
