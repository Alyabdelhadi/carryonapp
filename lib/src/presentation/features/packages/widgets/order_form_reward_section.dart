import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';

import 'order_form_choice_chip.dart';
import 'order_form_section_card.dart';

/// "Carrier Reward": Free, the preset amounts, or a custom amount.
class OrderFormRewardSection extends StatelessWidget {
  const OrderFormRewardSection({
    super.key,
    required this.options,
    required this.rewardChip,
    required this.onRewardChip,
    required this.customRewardController,
    required this.customRewardFocus,
    required this.onCustomReward,
  });

  final List<String> options;
  final String? rewardChip;
  final ValueChanged<String> onRewardChip;
  final TextEditingController customRewardController;
  final FocusNode customRewardFocus;
  final ValueChanged<String> onCustomReward;

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
            Padding(
              padding: EdgeInsets.only(top: context.dimensions.space.s12),
              child: TextField(
                controller: customRewardController,
                focusNode: customRewardFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                textInputAction: TextInputAction.done,
                textDirection: TextDirection.ltr,
                onChanged: onCustomReward,
                decoration: InputDecoration(
                  hintText: l10n.pkwEnterRewardAmount,
                  prefixText: '\$ ',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
