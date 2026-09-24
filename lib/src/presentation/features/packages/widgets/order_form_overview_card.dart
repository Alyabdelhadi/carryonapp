import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';

/// The Ionic "Package Overview" sidebar: what has been chosen so far.
/// Renders nothing until at least one line has a value.
class OrderFormOverviewCard extends StatelessWidget {
  const OrderFormOverviewCard({
    super.key,
    required this.categoryName,
    required this.weight,
    required this.value,
    required this.reward,
    required this.neededBefore,
    required this.distanceKm,
    this.paymentLabel,
  });

  final String? categoryName;
  final String? weight;
  final String? value;
  final String? reward;
  final DateTime? neededBefore;
  final double? distanceKm;

  /// "Card (Stripe)" / "Cash on delivery"; shown once a reward is chosen.
  final String? paymentLabel;

  /// `formatValue` of the Ionic page: the declared number with the dollar
  /// sign in front.
  static String formatValue(String value) => '\$${value.trim()}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <(String, String)>[
      if (categoryName != null && categoryName!.isNotEmpty)
        (l10n.pkwPackageType, categoryName!),
      if (weight != null && weight!.isNotEmpty) (l10n.pkwWeight, weight!),
      if (value != null && value!.isNotEmpty)
        (l10n.pkwValue, formatValue(value!)),
      if (reward != null && reward!.isNotEmpty)
        (l10n.pkwCarrierReward, Formatters.reward(reward, free: l10n.free)),
      if (reward != null && reward!.isNotEmpty && paymentLabel != null)
        (l10n.pkwPayment, paymentLabel!),
      if (neededBefore != null)
        (l10n.pkwNeededBefore, Formatters.monthDayYear(neededBefore)),
      if (distanceKm != null)
        (
          l10n.pkwDistance,
          Formatters.distanceKm(distanceKm, unit: l10n.kmUnit),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      margin: EdgeInsets.only(bottom: context.dimensions.space.s16),
      color: context.color.primary.tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: context.dimensions.size.iconMedium,
                color: context.color.primary.strong,
              ),
              Gap(context.dimensions.space.s8),
              HeadingLevel3Text(l10n.pkwPackageOverview),
            ],
          ),
          Gap(context.dimensions.space.s8),
          for (final (label, text) in rows)
            DetailRow(label: label, value: text),
        ],
      ),
    );
  }
}
