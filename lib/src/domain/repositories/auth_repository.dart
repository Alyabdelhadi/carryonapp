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

  /// Fetches the fresh profile with stats and refreshes the stored user.
  Future<Result<AppUser, BusinessFailure>> fetchUser(int id);

  Future<Result<AppUser, BusinessFailure>> updateProfile(
    int id,
    ProfileUpdateInput input,
  );

  /// Soft-deletes the account and clears the session.
  Future<Result<String, BusinessFailure>> deleteAccount(int id);

  /// Emails a password reset link. Resolves to the server's message.
  Future<Result<String, BusinessFailure>> sendResetLink(String email);

  Future<Result<Unit, BusinessFailure>> logout();

  /// Rates the other party of an order once.
  Future<Result<Unit, BusinessFailure>> rateOrder({
    required int userId,
    required int orderId,
    required double rating,
  });
}
