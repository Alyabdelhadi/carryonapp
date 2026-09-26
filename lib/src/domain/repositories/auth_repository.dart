import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../entities/app_user.dart';
import '../entities/auth_inputs.dart';
import '../failures/business_failure.dart';

abstract interface class AuthRepository {
  /// Signs in and persists the session on success.
  Future<Result<AppUser, BusinessFailure>> login({
    required String email,
    required String password,
  });

  /// Creates the account (multipart with selfie + identity) and persists
  /// the session on success.
  Future<Result<AppUser, BusinessFailure>> signup(SignupInput input);

  /// Sends a new selfie + ID for an existing account; the backend runs the
  /// Shufti check. Resolves to the updated user (verified, or pending when
  /// Shufti has no verdict yet) and stores it.
  Future<Result<AppUser, BusinessFailure>> verifyIdentity({
    required int userId,
    required String selfiePath,
    required String identityPath,
  });

  /// Opens a live Shufti session (admin live mode) and returns the page the
  /// user completes in a browser, or null when there is nothing to verify
  /// (already verified or under review; the stored user is refreshed).
  Future<Result<Uri?, BusinessFailure>> startLiveIdentity({
    required int userId,
    required String languageCode,
  });

  /// Asks the backend to re-check a pending identity review with Shufti
  /// and stores the result.
  Future<Result<AppUser, BusinessFailure>> refreshIdentity(int userId);

  /// Fetches the fresh profile with stats and refreshes the stored user.
  Future<Result<AppUser, BusinessFailure>> fetchUser(int id);

  Future<Result<AppUser, BusinessFailure>> updateProfile(
    int id,
    ProfileUpdateInput input,
  );

  /// Soft-deletes the account and clears the session.
  Future<Result<String, BusinessFailure>> deleteAccount(int id);

  /// Emails a 6-digit reset code (the answer is the same for unknown
  /// emails). Resolves to the seconds before another code can be sent.
  Future<Result<int, BusinessFailure>> requestPasswordResetCode({
    required String email,
    required String languageCode,
  });

  /// Checks the emailed code; resolves to the one-time reset ticket.
  Future<Result<PasswordResetTicket, BusinessFailure>> verifyPasswordResetCode({
    required String email,
    required String code,
  });

  /// Sets the new password with a ticket from [verifyPasswordResetCode].
  Future<Result<Unit, BusinessFailure>> resetPassword({
    required PasswordResetTicket ticket,
    required String password,
  });

  Future<Result<Unit, BusinessFailure>> logout();

  /// Rates the other party of an order once.
  Future<Result<Unit, BusinessFailure>> rateOrder({
    required int userId,
    required int orderId,
    required double rating,
  });
}
