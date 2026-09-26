import 'package:dio/dio.dart';

import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_inputs.dart';
import '../../domain/failures/business_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../base/repository.dart';
import '../failures/infra_failure.dart';
import '../mappers/json_mappers.dart';
import '../services/network/auth/token_manager.dart';
import '../services/network/exceptions.dart';
import '../services/network/rest_client.dart';

final class AuthRepositoryImpl extends Repository implements AuthRepository {
  AuthRepositoryImpl({
    required this.remote,
    required this.session,
    required this.tokens,
    required super.crashReporter,
  });

  final RestClient remote;
  final SessionRepository session;
  final TokenManager tokens;

  /// Login, signup and a password change answer with a fresh token pair.
  Future<void> _persistTokens(Map<String, dynamic> body) async {
    final access = Json.toStr(body['accessToken']);
    if (access == null || access.isEmpty) return;
    final expiresIn = Json.toInt(body['expiresIn']);
    await tokens.persist(
      access: access,
      refresh: Json.toStr(body['refreshToken']),
      expiresIn: expiresIn == null ? null : Duration(seconds: expiresIn),
    );
  }

  @override
  Future<Result<AppUser, BusinessFailure>> login({
    required String email,
    required String password,
  }) {
    return asyncGuard(() async {
      final response = await remote.login({
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      final body = Json.requireDone(response.data);
      final user = AppUserMapper.fromJson(Json.asMap(body['user']));
      await _persistTokens(body);
      await session.saveUser(user);
      return user;
    });
  }

  @override
  Future<Result<AppUser, BusinessFailure>> signup(SignupInput input) {
    return asyncGuard(() async {
      final form = FormData.fromMap({
        'name': input.name,
        'email': input.email.trim().toLowerCase(),
        'phone': input.phone,
        'password': input.password,
        'country': input.country ?? '',
        'city': input.city ?? '',
        'role': input.role,
        if (input.referralCode != null && input.referralCode!.isNotEmpty)
          'rcode': input.referralCode,
        'selfie': await MultipartFile.fromFile(input.selfiePath),
        if (input.identityPath != null)
          'identity': await MultipartFile.fromFile(input.identityPath!),
      });
      final response = await remote.signup(form);
      final body = Json.requireDone(response.data);
      final user = AppUserMapper.fromJson(Json.asMap(body['user']));
      await _persistTokens(body);
      await session.saveUser(user);
      return user;
    }, recover: _identityFailure);
  }

  @override
  Future<Result<AppUser, BusinessFailure>> verifyIdentity({
    required int userId,
    required String selfiePath,
    required String identityPath,
  }) {
    return asyncGuard(() async {
      final form = FormData.fromMap({
        'user_id': userId,
        'selfie': await MultipartFile.fromFile(selfiePath),
        'identity': await MultipartFile.fromFile(identityPath),
      });
      final response = await remote.verifyIdentity(form);
      return _saveUserFrom(response.data);
    }, recover: _identityFailure);
  }

  @override
  Future<Result<Uri?, BusinessFailure>> startLiveIdentity({
    required int userId,
    required String languageCode,
  }) {
    return asyncGuard(() async {
      final response = await remote.startLiveIdentity({
        'user_id': userId,
        'lang': languageCode,
      });
      final body = Json.requireDone(response.data);
      final url = Json.toStr(body['verification_url']);
      if (url == null) {
        await _saveUserFrom(body);
        return null;
      }
      return Uri.parse(url);
    }, recover: _identityFailureOf);
  }

  @override
  Future<Result<AppUser, BusinessFailure>> refreshIdentity(int userId) {
    return asyncGuard(() async {
      final response = await remote.identityStatus(userId);
      return _saveUserFrom(response.data);
    });
  }

  /// These endpoints answer with the bare user (no stats), so the stored
  /// stats are kept and only the identity fields move forward.
  Future<AppUser> _saveUserFrom(Object? data) async {
    final body = Json.requireDone(data);
    final fresh = AppUserMapper.fromJson(Json.asMap(body['user']));
    final stored = session.user;
    final user = stored != null && stored.id == fresh.id
        ? stored.copyWith(
            selfie: fresh.selfie,
            identity: fresh.identity,
            identityStatus: fresh.identityStatus,
          )
        : fresh;
    await session.saveUser(user);
    return user;
  }

  /// A refused identity check becomes a failure the UI shows with
  /// localized copy (see `BusinessFailureUIMapper`).
  static Result<AppUser, BusinessFailure>? _identityFailure(
    InfraFailure failure,
  ) => _identityFailureOf<AppUser>(failure);

  static Result<T, BusinessFailure>? _identityFailureOf<T>(
    InfraFailure failure,
  ) {
    final cause = failure.cause;
    if (cause is! IdentityRejectedException) return null;
    final identity = IdentityVerificationFailure(
      cause.kind,
      detail: cause.detail,
    );
    return Error(
      cause.kind == IdentityVerificationFailureKind.unreachable
          ? BusinessFailure.unreachable(cause: identity)
          : BusinessFailure.invalidInput(cause: identity),
    );
  }

  @override
  Future<Result<AppUser, BusinessFailure>> fetchUser(int id) {
    return asyncGuard(() async {
      final response = await remote.userInfo(id);
      final body = Json.requireDone(response.data);
      final user = AppUserMapper.fromJson(Json.asMap(body['user']));
      if (session.userId == user.id) await session.saveUser(user);
      return user;
    });
  }

  @override
  Future<Result<AppUser, BusinessFailure>> updateProfile(
    int id,
    ProfileUpdateInput input,
  ) {
    return asyncGuard(() async {
      final form = FormData.fromMap({
        'name': input.name,
        'email': input.email.trim().toLowerCase(),
        'phone': input.phone,
        'country': input.country ?? '',
        'city': input.city ?? '',
        if (input.password != null && input.password!.isNotEmpty) ...{
          'password': input.password,
          'current_password': input.currentPassword ?? '',
        },
        if (input.selfiePath != null)
          'selfie': await MultipartFile.fromFile(input.selfiePath!),
        if (input.identityPath != null)
          'identity': await MultipartFile.fromFile(input.identityPath!),
      });
      final response = await remote.updateInfo(id, form);
      final body = Json.requireDone(response.data);
      final user = AppUserMapper.fromJson(Json.asMap(body['user']));
      // a password change signs out every device and hands this one a new pair
      await _persistTokens(body);
      await session.saveUser(user);
      return user;
    });
  }

  @override
  Future<Result<String, BusinessFailure>> deleteAccount(int id) {
    return asyncGuard(() async {
      final response = await remote.deleteUser(id);
      final body = Json.asMap(response.data);
      final message = Json.str(body['message']);
      // The backend answers with prose; only the "deactivated" sentence
      // means it went through.
      if (!message.toLowerCase().contains('deactivated')) {
        throw ApiResponseException(message);
      }
      await tokens.clear();
      await session.clearSession();
      return message;
    });
  }

  @override
  Future<Result<int, BusinessFailure>> requestPasswordResetCode({
    required String email,
    required String languageCode,
  }) {
    return asyncGuard(() async {
      final response = await remote.requestPasswordResetCode({
        'email': email.trim().toLowerCase(),
        'lang': languageCode,
      });
      final body = Json.requireDone(response.data);
      return Json.toInt(body['resend_in']) ?? 60;
    });
  }

  @override
  Future<Result<PasswordResetTicket, BusinessFailure>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) {
    return asyncGuard(() async {
      final response = await remote.verifyPasswordResetCode({
        'email': email.trim().toLowerCase(),
        'code': code,
      });
      final body = Json.requireDone(response.data);
      return PasswordResetTicket(
        userId: Json.toInt(body['user_id']) ?? 0,
        token: Json.str(body['token']),
      );
    }, recover: _passwordResetFailure);
  }

  @override
  Future<Result<Unit, BusinessFailure>> resetPassword({
    required PasswordResetTicket ticket,
    required String password,
  }) {
    return asyncGuard(() async {
      final response = await remote.resetPassword({
        'user_id': ticket.userId,
        'token': ticket.token,
        'password': password,
      });
      Json.requireDone(response.data);
      return Unit.value;
    }, recover: _passwordResetFailure);
  }

  /// A refused code or expired session becomes a failure with localized
  /// copy (see `BusinessFailureUIMapper`).
  static Result<T, BusinessFailure>? _passwordResetFailure<T>(
    InfraFailure failure,
  ) {
    final cause = failure.cause;
    if (cause is! PasswordResetRejectedException) return null;
    return Error(
      BusinessFailure.invalidInput(cause: PasswordResetFailure(cause.kind)),
    );
  }

  @override
  Future<Result<Unit, BusinessFailure>> logout() {
    return asyncGuard(() async {
      try {
        // best effort: the local sign-out must not depend on the network
        await remote.logout();
      } on Exception catch (_) {}
      await tokens.clear();
      await session.clearSession();
      return Unit.value;
    });
  }

  @override
  Future<Result<Unit, BusinessFailure>> rateOrder({
    required int userId,
    required int orderId,
    required double rating,
  }) {
    return asyncGuard(() async {
      final response = await remote.rate({
        'user_id': userId,
        'order_id': orderId,
        'rating': rating,
      });
      Json.requireDone(response.data);
      return Unit.value;
    });
  }
}
