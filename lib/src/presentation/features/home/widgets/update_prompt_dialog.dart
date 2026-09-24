import 'package:flutter/material.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';

/// What the user picked on the update prompt.
enum UpdateChoice { remindTomorrow, updateNow }

/// The store-update alert. It cannot be dismissed by tapping outside or
/// with the back gesture; it pops with an [UpdateChoice].
class UpdatePromptDialog extends StatelessWidget {
  const UpdatePromptDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
  });

  final String currentVersion;
  final String latestVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            context.dimensions.radius.extraLarge,
          ),
        ),
        title: Text(l10n.homeUpdateAvailableTitle),
        content: Text(
          l10n.homeUpdateAvailableBody(latestVersion, currentVersion),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(UpdateChoice.remindTomorrow),
            child: Text(l10n.homeRemindTomorrow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(UpdateChoice.updateNow),
            child: Text(l10n.homeUpdateNow),
          ),
        ],
      ),
    );
  }
}
