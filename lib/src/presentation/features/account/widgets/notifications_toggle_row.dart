import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../domain/failures/business_failure.dart';
import '../../../core/widgets/feedback.dart';
import 'menu_row.dart';

/// The push-notifications switch. Starts from the stored preference,
/// flips optimistically, and on failure reverts and alerts exactly as the
/// original account screen did.
class NotificationsToggleRow extends ConsumerStatefulWidget {
  const NotificationsToggleRow({super.key});

  @override
  ConsumerState<NotificationsToggleRow> createState() =>
      _NotificationsToggleRowState();
}

class _NotificationsToggleRowState
    extends ConsumerState<NotificationsToggleRow> {
  late bool _enabled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _enabled = ref.read(getSessionUseCaseProvider).notificationsEnabled;
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() {
      _enabled = value;
      _busy = true;
    });

    final result = await ref
        .read(setNotificationsEnabledUseCaseProvider)
        .call(value);
    if (!mounted) return;

    setState(() => _busy = false);

    switch (result) {
      case Success():
        AppFeedback.toast(
          context,
          value ? l10n.accNotificationsEnabled : l10n.accNotificationsDisabled,
        );
      case Error(:final error):
        setState(() => _enabled = !value);
        if (error is PermissionDenied) {
          await AppFeedback.alert(
            context,
            title: l10n.accPermissionRequired,
            message: l10n.accNotificationsPermissionMessage,
          );
        } else {
          await AppFeedback.alert(
            context,
            title: l10n.accErrorTitle,
            message: l10n.accNotificationsUpdateFailed,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuRow(
      icon: Icons.notifications_outlined,
      label: context.l10n.accNotifications,
      trailing: Switch.adaptive(
        value: _enabled,
        onChanged: _busy ? null : _toggle,
      ),
    );
  }
}
