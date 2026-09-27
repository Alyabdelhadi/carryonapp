import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../../core/config/app_config.dart';
import '../../core/logger/log.dart';
import '../../domain/failures/business_failure.dart';
import '../../domain/repositories/notification_repository.dart';
import '../base/repository.dart';
import '../services/network/exceptions.dart';

/// FCM topic membership. Firebase itself is initialised in `bootstrap`;
/// when that failed (missing platform config) every call here fails
/// softly with a business failure instead of crashing.
final class NotificationRepositoryImpl extends Repository
    implements NotificationRepository {
  NotificationRepositoryImpl({
    required this.firebaseReady,
    required super.crashReporter,
  });

  final bool firebaseReady;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  void _requireFirebase() {
    if (!firebaseReady) {
      throw const ApiResponseException(
        'Push notifications are not configured on this build',
      );
    }
  }

  Future<bool> _requestPermission() async {
    final settings = await _fcm.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// iOS: topic calls throw `apns-token-not-set` until APNs has handed the
  /// app its token, which can land a moment after permission is granted
  /// (and never without the `aps-environment` entitlement). Waits a few
  /// seconds for it; true when it is there (always true off iOS).
  Future<bool> _apnsReady() async {
    if (!Platform.isIOS) return true;
    for (var i = 0; i < 10; i++) {
      if (await _fcm.getAPNSToken() != null) return true;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    Log.warning('APNs token unavailable; push topics skipped');
    return false;
  }

  @override
  Future<Result<Unit, BusinessFailure>> enable({int? userId}) {
    return asyncGuard(() async {
      _requireFirebase();
      if (!await _requestPermission()) {
        throw const ApiResponseException('Notification permission denied');
      }
      // The token is only logged; on a simulator (no APNs) the lookup throws
      // and must not block the topic subscriptions below.
      try {
        final token = await _fcm.getToken();
        Log.info('FCM token: $token');
      } on Object catch (e) {
        Log.warning('FCM token unavailable: $e');
      }
      if (!await _apnsReady()) {
        throw const ApiResponseException('Push notifications unavailable');
      }
      await _fcm.subscribeToTopic(AppConfig.broadcastTopic);
      if (userId != null) {
        await _fcm.subscribeToTopic(AppConfig.userTopic(userId));
      }
      return Unit.value;
    });
  }

  @override
  Future<Result<Unit, BusinessFailure>> disable({int? userId}) {
    return asyncGuard(() async {
      _requireFirebase();
      // no APNs token means this device was never subscribed: nothing to undo
      if (!await _apnsReady()) return Unit.value;
      await _fcm.unsubscribeFromTopic(AppConfig.broadcastTopic);
      if (userId != null) {
        await _fcm.unsubscribeFromTopic(AppConfig.userTopic(userId));
      }
      return Unit.value;
    });
  }

  @override
  Future<Result<Unit, BusinessFailure>> subscribeUser(int userId) {
    return asyncGuard(() async {
      _requireFirebase();
      if (!await _apnsReady()) {
        throw const ApiResponseException('Push notifications unavailable');
      }
      await _fcm.subscribeToTopic(AppConfig.userTopic(userId));
      return Unit.value;
    });
  }

  @override
  Future<Result<Unit, BusinessFailure>> unsubscribeUser(int userId) {
    return asyncGuard(() async {
      _requireFirebase();
      if (!await _apnsReady()) return Unit.value;
      await _fcm.unsubscribeFromTopic(AppConfig.userTopic(userId));
      return Unit.value;
    });
  }
}
