import '../../core/base/result.dart';
import '../entities/auth_inputs.dart';
import '../failures/business_failure.dart';

/// Selfie + document match performed before an account is created.
abstract interface class IdentityVerificationRepository {
  Future<Result<IdentityVerification, BusinessFailure>> verify({
    required String selfiePath,
    required String identityPath,
    required String email,
  });
}
