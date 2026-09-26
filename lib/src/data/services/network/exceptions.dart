import '../../../domain/entities/auth_inputs.dart';

/// Sentinel raised by `AuthHeaderInterceptor` when a `RequestAuth.protected`
/// request has no access token to send. The exception classifier maps it to
/// `InfraFailure.unauthorized` → `BusinessFailure.unauthenticated`, so the
/// user sees the session-expired flow instead of a generic failure
/// message.
class MissingAccessTokenException implements Exception {
  const MissingAccessTokenException();

  @override
  String toString() => 'Access token is missing';
}

/// The CarryOn backend reports most business failures with HTTP 200 and a
/// message in the body (`{"msg":"error","error":"Oops! ..."}` or
/// `{"message":"Parcel order ... not found"}`). Mappers throw this so the
/// classifier can surface the server's own text as an
/// `InfraFailure.validation` → `BusinessFailure.invalidInput`.
class ApiResponseException implements Exception {
  const ApiResponseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The backend refused an identity check (`"reason": "identity_*"` next
/// to the usual error). Repositories turn it into a `BusinessFailure`
/// whose cause is an `IdentityVerificationFailure`.
class IdentityRejectedException extends ApiResponseException {
  const IdentityRejectedException(
    super.message, {
    required this.kind,
    this.detail,
  });

  final IdentityVerificationFailureKind kind;

  /// Shufti's own explanation, when it gave one.
  final String? detail;
}

/// The backend refused a password-reset step (`"reason": "otp_*"` or
/// `token_expired`).
class PasswordResetRejectedException extends ApiResponseException {
  const PasswordResetRejectedException(super.message, {required this.kind});

  final PasswordResetFailureKind kind;
}
