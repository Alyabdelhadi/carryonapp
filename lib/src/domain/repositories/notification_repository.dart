import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../failures/business_failure.dart';

/// Push topic membership. The backend publishes to the `carryon`
/// broadcast topic and to `user_<id>`; the app never registers device
/// tokens with the server.
abstract interface class NotificationRepository {
  /// Requests permission and subscribes to the broadcast topic plus the
  /// user topic when [userId] is given. Safe to call repeatedly.
  Future<Result<Unit, BusinessFailure>> enable({int? userId});

  /// Leaves both topics.
  Future<Result<Unit, BusinessFailure>> disable({int? userId});

  /// Joins only the user topic (after login / signup).
  Future<Result<Unit, BusinessFailure>> subscribeUser(int userId);

  /// Leaves only the user topic (after logout).
  Future<Result<Unit, BusinessFailure>> unsubscribeUser(int userId);
}
