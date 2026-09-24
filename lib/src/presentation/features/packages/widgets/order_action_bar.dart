import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';

/// One button of the sticky action bar.
class OrderAction {
  const OrderAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  /// Red fill (cancel / drop).
  final bool destructive;

  /// Outlined, for a supporting action next to the primary one (Edit).
  final bool secondary;
}

/// The sticky bottom bar under the order detail: the primary action for
/// the current status and role, plus any secondary ones.
class OrderActionBar extends StatelessWidget {
  const OrderActionBar({super.key, required this.actions, this.enabled = true});

  final List<OrderAction> actions;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.color.background.surface,
        boxShadow: context.dimensions.elevation.navigation,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.dimensions.space.s16,
            context.dimensions.space.s12,
            context.dimensions.space.s16,
            context.dimensions.space.s12,
          ),
          child: Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) Gap(context.dimensions.space.s12),
                Expanded(
                  flex: actions[i].secondary ? 2 : 3,
                  child: OrderActionButton(
                    action: actions[i],
                    enabled: enabled,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OrderActionButton extends StatelessWidget {
  const OrderActionButton({
    super.key,
    required this.action,
    required this.enabled,
  });

  final OrderAction action;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final onPressed = enabled ? action.onPressed : null;
    final icon = action.icon == null
        ? null
        : Icon(action.icon, size: context.dimensions.size.iconMedium);
    final label = Text(action.label);

    if (action.secondary) {
      return icon == null
          ? OutlinedButton(onPressed: onPressed, child: label)
          : OutlinedButton.icon(onPressed: onPressed, icon: icon, label: label);
    }
    final style = action.destructive
        ? FilledButton.styleFrom(
            backgroundColor: context.color.status.danger,
            foregroundColor: context.color.text.onPrimary,
          )
        : null;
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: label)
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: icon,
            label: label,
          );
  }
}
