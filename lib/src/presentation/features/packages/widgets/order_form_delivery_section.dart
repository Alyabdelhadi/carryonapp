import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/text/typography.dart';
import 'order_form_choice_chip.dart';
import 'order_form_section_card.dart';

/// "Delivery": "Needed Soon" versus "Needed Before" a date.
class OrderFormDeliverySection extends StatelessWidget {
  const OrderFormDeliverySection({
    super.key,
    required this.neededSoon,
    required this.neededBefore,
    required this.onNeededSoon,
    required this.onNeededBefore,
    required this.onPickDate,
  });

  final bool neededSoon;
  final DateTime? neededBefore;
  final VoidCallback onNeededSoon;
  final VoidCallback onNeededBefore;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OrderFormSectionCard(
      icon: Icons.schedule_outlined,
      title: l10n.pkwDelivery,
      subtitle: l10n.pkwDeliverySubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: context.dimensions.space.s8,
            runSpacing: context.dimensions.space.s8,
            children: [
              OrderFormChoiceChip(
                label: l10n.pkwNeededSoon,
                selected: neededSoon,
                onTap: onNeededSoon,
              ),
              OrderFormChoiceChip(
                label: l10n.pkwNeededBefore,
                selected: !neededSoon,
                onTap: onNeededBefore,
              ),
            ],
          ),
          if (!neededSoon) ...[
            Gap(context.dimensions.space.s12),
            Material(
              color: context.color.background.canvas,
              borderRadius: BorderRadius.circular(
                context.dimensions.radius.medium,
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPickDate,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.dimensions.space.s12,
                    vertical: context.dimensions.space.s12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: context.dimensions.size.iconMedium,
                        color: context.color.text.muted,
                      ),
                      Gap(context.dimensions.space.s8),
                      Expanded(child: LabelText(l10n.pkwSelectDate)),
                      BodySmallText(
                        neededBefore == null
                            ? l10n.pkwPickADate
                            : Formatters.weekdayMonthDay(neededBefore),
                      ),
                      Gap(context.dimensions.space.s4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: context.dimensions.size.iconMedium,
                        color: context.color.text.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
