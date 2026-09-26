import 'identity_status.dart';

/// A CarryOn account. The same record acts as a sender and as a carrier;
/// `role` is contextual and the backend reports `carrier` from `userInfo`.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role,
    this.status,
    this.country,
    this.city,
    this.selfie,
    this.identity,
    this.referralCode,
    this.wallet,
    this.treesSaved,
    this.carriedPackagesCount,
    this.packagesCount,
    this.averageRating,
    this.ratingsCount,
    this.identityStatus = IdentityStatus.none,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String? role;
  final int? status;
  final String? country;
  final String? city;

  /// File name under `upload/selfies/`.
  final String? selfie;

  /// File name under `upload/identities/`.
  final String? identity;
  final String? referralCode;
  final int? wallet;
  final double? treesSaved;
  final int? carriedPackagesCount;
  final int? packagesCount;
  final double? averageRating;
  final int? ratingsCount;

  /// The backend's Shufti check. Whether it matters at all depends on the
  /// admin switch (`AppSettings.shuftiEnabled`).
  final IdentityStatus identityStatus;

  bool get isVerified => identityStatus == IdentityStatus.verified;

  String get firstName => name.trim().split(' ').first;

  bool get isCarrier => role == 'carrier';

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? country,
    String? city,
    String? selfie,
    String? identity,
    IdentityStatus? identityStatus,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status,
      country: country ?? this.country,
      city: city ?? this.city,
      selfie: selfie ?? this.selfie,
      identity: identity ?? this.identity,
      referralCode: referralCode,
      wallet: wallet,
      treesSaved: treesSaved,
      carriedPackagesCount: carriedPackagesCount,
      packagesCount: packagesCount,
      averageRating: averageRating,
      ratingsCount: ratingsCount,
      identityStatus: identityStatus ?? this.identityStatus,
    );
  }
}
