/// Where an account stands with the backend's Shufti identity check
/// (`identity_status` / `is_verified` on the user).
enum IdentityStatus {
  /// Never verified: an account from before the check existed, or one
  /// created while the admin had the check switched off.
  none,

  /// Shufti has not given a verdict yet; the account is under review.
  pending,

  verified,

  /// The last attempt was rejected (face and document did not match).
  declined,

  /// The last attempt's photos could not be read.
  invalid;

  static IdentityStatus fromWire(Object? status, {Object? isVerified}) {
    if (isVerified == true || isVerified == 1 || status == 'verified') {
      return verified;
    }
    return switch (status) {
      'pending' => pending,
      'declined' => declined,
      'invalid' => invalid,
      _ => none,
    };
  }
}
