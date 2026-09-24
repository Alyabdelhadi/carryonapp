import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../entities/app_user.dart';
import '../entities/auth_inputs.dart';
import '../failures/business_failure.dart';
import '../repositories/auth_repository.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/identity_verification_repository.dart';
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

/// Signup is two steps, as in the original app: the selfie and document
/// are checked with Shufti first, and the account is only created when the
/// check was not declined. The admin can switch the Shufti step off
/// (`/appSettings`), in which case the photos are still uploaded for
/// manual review.
final class SignupUseCase {
  SignupUseCase(
    this.auth,
    this.identity,
    this.notifications,
    this.session,
    this.catalog,
  );

  final AuthRepository auth;
  final IdentityVerificationRepository identity;
  final NotificationRepository notifications;
  final SessionRepository session;
  final CatalogRepository catalog;

  Future<Result<AppUser, BusinessFailure>> call(SignupInput input) async {
    final settings = await catalog.appSettings();
    final shuftiEnabled = switch (settings) {
      Success(:final data) => data.shuftiEnabled,
      Error() => true,
    };
    if (!shuftiEnabled) {
      return _createAccount(input, shuftiStatus: 'skipped');
    }

    final check = await identity.verify(
      selfiePath: input.selfiePath,
      identityPath: input.identityPath,
      email: input.email,
    );
    IdentityVerification? verification;
    switch (check) {
      case Success(:final data):
        if (data.isDeclined) {
          return const Error(
            BusinessFailure.invalidInput(
              cause: IdentityVerificationFailure(
                IdentityVerificationFailureKind.declined,
              ),
            ),
          );
        }
        if (data.isInvalid) {
          return Error(
            BusinessFailure.invalidInput(
              cause: IdentityVerificationFailure(
                IdentityVerificationFailureKind.invalid,
                detail: data.message,
              ),
            ),
          );
        }
        verification = data;
      case Error():
        return const Error(
          BusinessFailure.unreachable(
            cause: IdentityVerificationFailure(
              IdentityVerificationFailureKind.unreachable,
            ),
          ),
        );
    }

    return _createAccount(
      input,
      shuftiReference: verification.reference,
      shuftiStatus: verification.event,
    );
  }

  Future<Result<AppUser, BusinessFailure>> _createAccount(
    SignupInput input, {
    String? shuftiReference,
    required String shuftiStatus,
  }) async {
    final result = await auth.signup(
      SignupInput(
        name: input.name,
        email: input.email,
        phone: input.phone,
        password: input.password,
        selfiePath: input.selfiePath,
        identityPath: input.identityPath,
        country: input.country,
        city: input.city,
        referralCode: input.referralCode,
        role: input.role,
        shuftiReference: shuftiReference,
        shuftiStatus: shuftiStatus,
      ),
    );
    if (result case Success(:final data)) {
      if (session.notificationsEnabled) {
        await notifications.subscribeUser(data.id);
      }
    }
    return result;
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
    if (result is Success) await notifications.unsubscribeUser(id);
    return result;
  }
}

final class SendResetLinkUseCase {
  SendResetLinkUseCase(this.auth);

  final AuthRepository auth;

  Future<Result<String, BusinessFailure>> call(String email) {
    return auth.sendResetLink(email);
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
    if (id != null) await notifications.unsubscribeUser(id);
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
