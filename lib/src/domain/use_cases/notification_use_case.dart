import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../failures/business_failure.dart';
import '../repositories/notification_repository.dart';
import '../repositories/session_repository.dart';

/// Push setup on launch: honours the account-screen opt-out, subscribes to
/// the broadcast topic and, when signed in, to the user topic.
final class SetupPushUseCase {
  SetupPushUseCase(this.notifications, this.session);

  final NotificationRepository notifications;
  final SessionRepository session;

  Future<void> call() async {
    if (!session.notificationsEnabled) return;
    await notifications.enable(userId: session.userId);
  }
}

/// The account-screen toggle.
final class SetNotificationsEnabledUseCase {
  SetNotificationsEnabledUseCase(this.notifications, this.session);

  final NotificationRepository notifications;
  final SessionRepository session;

  Future<Result<Unit, BusinessFailure>> call(bool enabled) async {
    final result = enabled
        ? await notifications.enable(userId: session.userId)
        : await notifications.disable(userId: session.userId);
    if (result is Success) await session.setNotificationsEnabled(enabled);
    return result;
  }
}
