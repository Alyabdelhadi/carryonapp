import 'package:dio/dio.dart';

import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_inputs.dart';
import '../../domain/failures/business_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../base/repository.dart';
import '../mappers/json_mappers.dart';
import '../services/network/exceptions.dart';
import '../services/network/rest_client.dart';

final class AuthRepositoryImpl extends Repository implements AuthRepository {
  AuthRepositoryImpl({
    required this.remote,
    required this.session,
    required super.crashReporter,
  });

  final RestClient remote;
  final SessionRepository session;

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
        if (input.shuftiReference != null)
          'shufti_reference': input.shuftiReference,
        if (input.shuftiStatus != null) 'shufti_status': input.shuftiStatus,
        'selfie': await MultipartFile.fromFile(input.selfiePath),
        'identity': await MultipartFile.fromFile(input.identityPath),
      });
      final response = await remote.signup(form);
      final body = Json.requireDone(response.data);
      final user = AppUserMapper.fromJson(Json.asMap(body['user']));
      await session.saveUser(user);
      return user;
    });
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
        if (input.password != null && input.password!.isNotEmpty)
          'password': input.password,
        if (input.selfiePath != null)
          'selfie': await MultipartFile.fromFile(input.selfiePath!),
        if (input.identityPath != null)
          'identity': await MultipartFile.fromFile(input.identityPath!),
      });
      final response = await remote.updateInfo(id, form);
      final body = Json.requireDone(response.data);
      final user = AppUserMapper.fromJson(Json.asMap(body['user']));
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
      await session.clearSession();
      return message;
    });
  }

  @override
  Future<Result<String, BusinessFailure>> sendResetLink(String email) {
    return asyncGuard(() async {
      final response = await remote.sendResetLink({
        'email': email.trim().toLowerCase(),
      });
      final body = Json.asMap(response.data);
      final status = Json.toStr(body['status']) ?? Json.toStr(body['msg']);
      final message =
          Json.toStr(body['message']) ?? Json.toStr(body['error']) ?? '';
      if (status != null && status.toLowerCase() == 'error') {
        throw ApiResponseException(message);
      }
      // The page shows its own localized confirmation; the server prose
      // (possibly empty) is only passed through.
      return message;
    });
  }

  @override
  Future<Result<Unit, BusinessFailure>> logout() {
    return asyncGuard(() async {
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
