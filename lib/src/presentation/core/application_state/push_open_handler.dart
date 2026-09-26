import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/base/result.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/logger/log.dart';
import '../router/router.dart';
import '../router/routes.dart';
import 'app_gate_provider/app_gate_provider.dart';

/// Opens the order a push notification is about when the user taps it
/// (`order_id` in the message data, set by the backend for payment and
/// status events). Both the cold-start message and taps while running.
void attachPushOpenHandler(ProviderContainer container) {
  if (!container.read(firebaseReadyProvider)) return;

  Future<void> open(RemoteMessage? message) async {
    final orderId = int.tryParse('${message?.data['order_id'] ?? ''}');
    if (orderId == null) return;
    final result = await container
        .read(fetchParcelOrderUseCaseProvider)
        .call(orderId);
    switch (result) {
      case Success(:final data):
        unawaited(
          container
              .read(goRouterProvider)
              .pushNamed(
                Routes.orderDetail.name,
                pathParameters: {'id': '$orderId'},
                extra: data,
              ),
        );
      case Error(:final error):
        Log.warning('Push tap: order $orderId not loaded: $error');
    }
  }

  // The backend pushes `type: identity` when a pending Shufti check gets
  // its verdict; re-evaluate the gate so the app unlocks (or asks again).
  void identityChanged(RemoteMessage message) {
    if (message.data['type'] == 'identity') {
      container.invalidate(identityGateProvider);
    }
  }

  unawaited(FirebaseMessaging.instance.getInitialMessage().then(open));
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    identityChanged(message);
    unawaited(open(message));
  });
  FirebaseMessaging.onMessage.listen(identityChanged);
}
