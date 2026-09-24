import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';

/// Shown to the creator of an expired order: pick a new "needed before"
/// date to put the package back in the pool.
class OrderExtendDateCard extends StatelessWidget {
  const OrderExtendDateCard({super.key, required this.onPickDate});

  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onPickDate,
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            color: context.color.status.danger,
          ),
          Gap(context.dimensions.space.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.pkwExtendDate,
                  style: context.textStyle.label.strong.copyWith(
                    color: context.color.status.danger,
                  ),
                ),
                BodySmallText.muted(context.l10n.pkwExtendDateHint),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.color.text.muted),
        ],
      ),
    );
  }
}
