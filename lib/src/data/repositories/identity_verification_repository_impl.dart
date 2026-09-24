import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/base/result.dart';
import '../../core/config/app_config.dart';
import '../../domain/entities/auth_inputs.dart';
import '../../domain/failures/business_failure.dart';
import '../../domain/repositories/identity_verification_repository.dart';
import '../base/repository.dart';
import '../mappers/json_mappers.dart';
import '../services/network/rest_client.dart';

/// Shufti Pro face + document verification, called directly from the
/// device exactly as the Ionic app did.
final class IdentityVerificationRepositoryImpl extends Repository
    implements IdentityVerificationRepository {
  IdentityVerificationRepositoryImpl({
    required this.remote,
    required super.crashReporter,
  });

  final RestClient remote;

  @override
  Future<Result<IdentityVerification, BusinessFailure>> verify({
    required String selfiePath,
    required String identityPath,
    required String email,
  }) {
    return asyncGuard(() async {
      final selfie = base64Encode(await File(selfiePath).readAsBytes());
      final document = base64Encode(await File(identityPath).readAsBytes());
      final credentials = base64Encode(
        utf8.encode('${AppConfig.shuftiClientId}:${AppConfig.shuftiSecretKey}'),
      );
      final payload = {
        'reference': 'SP_${DateTime.now().millisecondsSinceEpoch}',
        'country': '',
        'language': 'EN',
        'email': email,
        'face': {'proof': selfie},
        'document': {
          'proof': document,
          'supported_types': ['passport', 'id_card', 'driving_license'],
        },
      };
      Object? data;
      try {
        data = (await remote.shuftiVerify('Basic $credentials', payload)).data;
      } on DioException catch (e) {
        // Shufti answers 4xx with a JSON body such as
        // {"event":"request.invalid","error":{"message":"..."}}: that is a
        // verdict on the photos, not a transport failure.
        final body = e.response?.data;
        if (body is Map && body['event'] != null) {
          data = body;
        } else {
          rethrow;
        }
      }
      final body = Json.asMap(data);
      final error = body['error'];
      return IdentityVerification(
        reference: Json.str(body['reference']),
        event: Json.str(body['event']),
        message: error is Map ? Json.toStr(error['message']) : null,
      );
    });
  }
}
