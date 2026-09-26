import 'dart:async';

import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../entities/app_user.dart';
import '../entities/auth_inputs.dart';
import '../entities/identity_status.dart';
import '../failures/business_failure.dart';
import '../repositories/auth_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/session_repository.dart';

final class LoginUseCase {
  LoginUseCase(this.auth, this.notifications, this.session);

  final AuthRepository auth;
  final NotificationRepository notifications;
  final SessionRepository session;

  Future<Result<AppUser, BusinessFailure>> call({
    required String email,
    required String password,
  }) async {
    final result = await auth.login(email: email, password: password);
    if (result case Success(:final data)) {
      if (session.notificationsEnabled) {
        // Best effort: a push failure must not fail the login.
        await notifications.subscribeUser(data.id);
      }
    }
    return result;
  }
}

/// Creates the account. With the admin's Shufti switch on, the backend
/// checks the selfie and ID before it creates anything and answers with an
/// identity failure (see `IdentityVerificationFailure`) when the check
/// does not pass; the account may also come back `pending` when Shufti has
/// no verdict yet.
final class SignupUseCase {
  SignupUseCase(this.auth, this.notifications, this.session);

  final AuthRepository auth;
  final NotificationRepository notifications;
  final SessionRepository session;

  Future<Result<AppUser, BusinessFailure>> call(SignupInput input) async {
    final result = await auth.signup(input);
    if (result case Success(:final data)) {
      if (session.notificationsEnabled) {
        await notifications.subscribeUser(data.id);
      }
    }
    return result;
  }
}

/// A signed-in account that is not verified sends a new selfie + ID.
final class VerifyIdentityUseCase {
  VerifyIdentityUseCase(this.auth);

  final AuthRepository auth;

  Future<Result<AppUser, BusinessFailure>> call({
    required int userId,
    required String selfiePath,
    required String identityPath,
  }) {
    return auth.verifyIdentity(
      userId: userId,
      selfiePath: selfiePath,
      identityPath: identityPath,
    );
  }

  /// Live mode: the Shufti page to open, or null when there is nothing to
  /// verify any more.
  Future<Result<Uri?, BusinessFailure>> startLive({
    required int userId,
    required String languageCode,
  }) {
    return auth.startLiveIdentity(userId: userId, languageCode: languageCode);
  }

  /// "Check again" while under review: the backend asks Shufti.
  Future<Result<AppUser, BusinessFailure>> refresh(int userId) {
    return auth.refreshIdentity(userId);
  }
}

/// What the identity check allows the signed-in user to do.
enum IdentityGate {
  /// Signed out, or the admin switched the Shufti check off.
  notRequired,

  verified,

  /// Shufti has no verdict yet: the user can browse but not send, receive
  /// or carry packages.
  underReview,

  /// Never verified (old account) or the last attempt was rejected: the
  /// app only shows the verification screen.
  required,
}

/// Decides the [IdentityGate] from the server's view of the user, falling
/// back to the stored user when the network is down.
final class ResolveIdentityGateUseCase {
  ResolveIdentityGateUseCase(this.auth, this.session);

  final AuthRepository auth;
  final SessionRepository session;

  Future<IdentityGate> call({required bool shuftiEnabled}) async {
    final userId = session.userId;
    if (userId == null || !shuftiEnabled) return IdentityGate.notRequired;

    final user = switch (await auth.fetchUser(userId)) {
      Success(:final data) => data,
      Error() => session.user,
    };
    return gateFor(user);
  }

  static IdentityGate gateFor(AppUser? user) {
    if (user == null) return IdentityGate.required;
    return switch (user.identityStatus) {
      IdentityStatus.verified => IdentityGate.verified,
      IdentityStatus.pending => IdentityGate.underReview,
      IdentityStatus.none ||
      IdentityStatus.declined ||
      IdentityStatus.invalid => IdentityGate.required,
    };
  }
}

final class FetchUserUseCase {
  FetchUserUseCase(this.auth);

  final AuthRepository auth;

  Future<Result<AppUser, BusinessFailure>> call(int id) => auth.fetchUser(id);
}

final class UpdateProfileUseCase {
  UpdateProfileUseCase(this.auth);

  final AuthRepository auth;

  Future<Result<AppUser, BusinessFailure>> call(
    int id,
    ProfileUpdateInput input,
  ) {
    return auth.updateProfile(id, input);
  }
}

final class DeleteAccountUseCase {
  DeleteAccountUseCase(this.auth, this.notifications);

  final AuthRepository auth;
  final NotificationRepository notifications;

  Future<Result<String, BusinessFailure>> call(int id) async {
    final result = await auth.deleteAccount(id);
    // WHY: not awaited. FCM topic calls can hang (offline, no APNs token)
    // and must not block leaving the account.
    if (result is Success) unawaited(notifications.unsubscribeUser(id));
    return result;
  }
}

/// Forgot password: email a code, check it, set the new password.
final class PasswordResetUseCase {
  PasswordResetUseCase(this.auth);

  final AuthRepository auth;

  /// Resolves to the seconds before another code can be requested.
  Future<Result<int, BusinessFailure>> requestCode({
    required String email,
    required String languageCode,
  }) {
    return auth.requestPasswordResetCode(
      email: email,
      languageCode: languageCode,
    );
  }

  Future<Result<PasswordResetTicket, BusinessFailure>> verifyCode({
    required String email,
    required String code,
  }) {
    return auth.verifyPasswordResetCode(email: email, code: code);
  }

  Future<Result<Unit, BusinessFailure>> resetPassword({
    required PasswordResetTicket ticket,
    required String password,
  }) {
    return auth.resetPassword(ticket: ticket, password: password);
  }
}

final class LogoutUseCase {
  LogoutUseCase(this.auth, this.notifications, this.session);

  final AuthRepository auth;
  final NotificationRepository notifications;
  final SessionRepository session;

  Future<Result<Unit, BusinessFailure>> call() async {
    final id = session.userId;
    final result = await auth.logout();
    // WHY: not awaited, see DeleteAccountUseCase.
    if (id != null) unawaited(notifications.unsubscribeUser(id));
    return result;
  }
}

final class RateOrderUseCase {
  RateOrderUseCase(this.auth);

  final AuthRepository auth;

  Future<Result<Unit, BusinessFailure>> call({
    required int userId,
    required int orderId,
    required double rating,
  }) {
    return auth.rateOrder(userId: userId, orderId: orderId, rating: rating);
  }
}
