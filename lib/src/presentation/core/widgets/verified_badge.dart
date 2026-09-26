import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/localization.dart';
import '../application_state/app_gate_provider/app_gate_provider.dart';
import '../theme/theme.dart';

/// A check mark next to a verified user's name. Shows only while the
/// admin has the Shufti identity check on; [compact] drops the label.
class VerifiedBadge extends ConsumerWidget {
  const VerifiedBadge({
    super.key,
    required this.verified,
    this.compact = false,
  });

  final bool verified;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!verified || !ref.watch(showVerifiedBadgeProvider)) {
      return const SizedBox.shrink();
    }
    final label = context.l10n.verifiedBadge;
    final color = context.color.status.success;
    final icon = Icon(
      Icons.verified_rounded,
      size: context.dimensions.size.iconMedium,
      color: color,
      semanticLabel: compact ? label : null,
    );
    if (compact) return Tooltip(message: label, child: icon);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dimensions.space.s8,
        vertical: context.dimensions.space.s2,
      ),
      decoration: BoxDecoration(
        color: context.color.status.successTint,
        borderRadius: BorderRadius.circular(context.dimensions.radius.large),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(width: context.dimensions.space.s4),
          Text(
            label,
            style: context.textStyle.label.strong.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
