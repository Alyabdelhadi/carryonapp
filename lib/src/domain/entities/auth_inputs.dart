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
    this.identityPath,
    this.country,
    this.city,
    this.referralCode,
    this.role = 0,
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

  /// Null in live verification mode, where the ID is scanned on Shufti's
  /// page after signup.
  final String? identityPath;
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
    this.currentPassword,
    this.selfiePath,
    this.identityPath,
  });

  final String name;
  final String email;
  final String phone;
  final String? country;
  final String? city;
  final String? password;

  /// Required by the backend whenever [password] is set.
  final String? currentPassword;
  final String? selfiePath;
  final String? identityPath;
}

/// Why the backend's identity check (signup or re-verification) did not
/// pass. Carried as the `cause` of a [BusinessFailure] so the UI can show
/// localized copy; [detail] is Shufti's own English explanation when it
/// gave one. `unreachable` means no verdict: try again later.
enum IdentityVerificationFailureKind {
  declined,
  invalid,
  unreachable,

  /// The admin switched to live verification; uploaded photos are refused.
  liveRequired,
}

class IdentityVerificationFailure {
  const IdentityVerificationFailure(this.kind, {this.detail});

  final IdentityVerificationFailureKind kind;
  final String? detail;
}

/// Proof that the emailed reset code was right: the one-time token the
/// backend issued for setting a new password.
class PasswordResetTicket {
  const PasswordResetTicket({required this.userId, required this.token});

  final int userId;
  final String token;
}

/// Why a password-reset step was refused. Carried as the `cause` of a
/// [BusinessFailure] so the UI shows localized copy.
enum PasswordResetFailureKind {
  /// Wrong code.
  invalidCode,

  /// The code is older than 10 minutes.
  expiredCode,

  /// Five wrong tries; a new code is needed.
  tooManyAttempts,

  /// The reset session (token) expired or was used; start again.
  sessionExpired,
}

class PasswordResetFailure {
  const PasswordResetFailure(this.kind);

  final PasswordResetFailureKind kind;
}
