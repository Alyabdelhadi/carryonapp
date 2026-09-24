import 'package:flutter/material.dart';

import '../../../core/extensions/localization.dart';
import '../../../domain/failures/business_failure.dart';
import '../failure/business_failure_ui_mapper.dart';
import '../theme/theme.dart';

/// Snackbar and dialog helpers so every screen reports outcomes the same
/// way. These are plain functions (not widgets) on purpose: they need a
/// `BuildContext` at call time, not a slot in the tree.
abstract final class AppFeedback {
  static void toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.color.background.inverse,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              context.dimensions.radius.medium,
            ),
          ),
        ),
      );
  }

  /// Shows the mapped copy of any error object (a [BusinessFailure] or
  /// anything else, which degrades to the generic message).
  static void error(BuildContext context, Object error) {
    final model = error is BusinessFailure
        ? BusinessFailureUIMapper.map(error, context.locale)
        : BusinessFailureUIMapper.unexpected(context.locale);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(model.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.color.status.danger,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              context.dimensions.radius.medium,
            ),
          ),
        ),
      );
  }

  /// A yes / no dialog. Resolves true when the user confirmed.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            dialogContext.dimensions.radius.extraLarge,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel ?? dialogContext.locale.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: dialogContext.color.status.danger,
                  )
                : null,
            child: Text(confirmLabel ?? dialogContext.locale.confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// A single-button information dialog.
  static Future<void> alert(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            dialogContext.dimensions.radius.extraLarge,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.locale.ok),
          ),
        ],
      ),
    );
  }
}
