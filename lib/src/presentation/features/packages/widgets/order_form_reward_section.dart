import 'package:flutter/material.dart';

import '../../../../core/extensions/localization.dart';

import 'order_form_choice_chip.dart';
import 'order_form_custom_input.dart';
import 'order_form_section_card.dart';

/// "Carrier Reward": Free, the preset amounts, or a custom amount.
class OrderFormRewardSection extends StatelessWidget {
  const OrderFormRewardSection({
    super.key,
    required this.options,
    required this.rewardChip,
    required this.onRewardChip,
    required this.customRewardController,
    required this.onAddReward,
  });

  final List<String> options;
  final String? rewardChip;
  final ValueChanged<String> onRewardChip;
  final TextEditingController customRewardController;
  final VoidCallback onAddReward;

  /// Chip values the form stores and sends; only their labels are localized.
  static const String free = 'Free';
  static const String other = 'Other';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OrderFormSectionCard(
      icon: Icons.volunteer_activism_outlined,
      title: l10n.pkwCarrierReward,
      subtitle: l10n.pkwCarrierRewardSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderFormChipGroup(
            options: options,
            selected: rewardChip,
            onSelect: onRewardChip,
            labelOf: (o) => switch (o) {
              free => l10n.free,
              other => l10n.pkwRewardOther,
              _ => '\$$o',
            },
          ),
          if (rewardChip == other)
            OrderFormCustomInput(
              controller: customRewardController,
              hint: l10n.pkwEnterRewardAmount,
              buttonLabel: l10n.pkwAddReward,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textDirection: TextDirection.ltr,
              onAdd: onAddReward,
            ),
        ],
      ),
    );
  }
}
