/// Everything the signup form submits. [phone] is the full number with the
/// country code written as `00<code>` (the backend convention), and the
/// two photo paths point at files picked on the device.
class SignupInput {
  const SignupInput({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.selfiePath,
    required this.identityPath,
    this.country,
    this.city,
    this.referralCode,
    this.role = 0,
    this.shuftiReference,
    this.shuftiStatus,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final String? country;
  final String? city;
  final String? referralCode;

  /// 1 when the user opted into carrying packages.
  final int role;
  final String selfiePath;
  final String identityPath;
  final String? shuftiReference;
  final String? shuftiStatus;
}

/// Fields the profile screen can change. Null photo paths keep the
/// existing files; a null password keeps the current one.
class ProfileUpdateInput {
  const ProfileUpdateInput({
    required this.name,
    required this.email,
    required this.phone,
    this.country,
    this.city,
    this.password,
    this.selfiePath,
    this.identityPath,
  });

  final String name;
  final String email;
  final String phone;
  final String? country;
  final String? city;
  final String? password;
  final String? selfiePath;
  final String? identityPath;
}

/// Outcome of a Shufti Pro selfie + document check.
class IdentityVerification {
  const IdentityVerification({
    required this.reference,
    required this.event,
    this.message,
  });

  final String reference;

  /// `verification.accepted`, `verification.declined`, `request.pending`,
  /// or `request.invalid` when Shufti could not read the photos.
  final String event;

  /// Shufti's explanation for a declined or invalid request.
  final String? message;

  bool get isDeclined => event == 'verification.declined';

  bool get isInvalid => event == 'request.invalid';
}

/// Why signup could not pass the identity check. Carried as the `cause`
/// of a [BusinessFailure] so the UI can show localized copy; [detail] is
/// Shufti's own English explanation when it gave one.
enum IdentityVerificationFailureKind { declined, invalid, unreachable }

class IdentityVerificationFailure {
  const IdentityVerificationFailure(this.kind, {this.detail});

  final IdentityVerificationFailureKind kind;
  final String? detail;
}
