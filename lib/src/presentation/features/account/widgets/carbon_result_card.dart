import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../model/carbon_calculator.dart';

/// Every figure the original printed for a route, in the same order:
/// distance, both emissions, the saving in CO₂ and trees, both costs and
/// the money saved. Eco figures wear the impact green.
class CarbonResultCard extends StatelessWidget {
  const CarbonResultCard({super.key, required this.estimate});

  final CarbonEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final color = context.color;
    final space = context.dimensions.space;
    final l10n = context.l10n;
    final e = estimate;
    final distance = Formatters.distanceKm(
      e.distanceKm.toDouble(),
      unit: l10n.kmUnit,
    );

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flight_takeoff_rounded,
                size: context.dimensions.size.iconMedium,
                color: color.accent.sky,
              ),
              Gap(space.s8),
              Expanded(child: HeadingLevel3Text(e.route)),
              LabelText.muted(distance),
            ],
          ),
          Gap(space.s12),
          Divider(
            height: context.dimensions.layout.hairline,
            thickness: context.dimensions.layout.hairline,
            color: color.border.subtle,
          ),
          Gap(space.s12),
          _ResultRow(
            icon: Icons.straighten_rounded,
            label: l10n.accDistance,
            value: distance,
          ),
          _ResultRow(
            icon: Icons.cloud_outlined,
            label: l10n.accTraditionalCo2,
            value: l10n.accKgValue(Formatters.compact(e.traditionalCo2Kg)),
          ),
          _ResultRow(
            icon: Icons.eco_outlined,
            label: l10n.accCarryonCo2,
            value: l10n.accKgValue(Formatters.compact(e.carryonCo2Kg)),
            tint: color.accent.eco,
          ),
          _ResultRow(
            icon: Icons.check_circle_outline_rounded,
            label: l10n.accCo2Saved,
            value: l10n.accKgValue(Formatters.compact(e.co2SavedKg)),
            tint: color.accent.eco,
          ),
          _ResultRow(
            icon: Icons.park_outlined,
            label: l10n.accTreesSaved,
            value: l10n.accTreesCount(Formatters.compact(e.treesSaved)),
            tint: color.accent.eco,
          ),
          _ResultRow(
            icon: Icons.local_shipping_outlined,
            label: l10n.accCargoCost,
            value: l10n.accUsdAmount(Formatters.compact(e.cargoCost)),
          ),
          _ResultRow(
            icon: Icons.rocket_launch_outlined,
            label: l10n.accCarryonCost,
            value: l10n.accUsdAmount(Formatters.compact(e.carryonCost)),
          ),
          _ResultRow(
            icon: Icons.celebration_outlined,
            label: l10n.accYouSave,
            value: l10n.accUsdAmount(Formatters.compact(e.youSave)),
            tint: color.status.success,
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final iconColor = tint ?? context.color.text.muted;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.space.s4),
      child: Row(
        children: [
          Icon(
            icon,
            size: context.dimensions.size.iconMedium,
            color: iconColor,
          ),
          Gap(context.dimensions.space.s8),
          Expanded(child: BodySmallText.muted(label)),
          Gap(context.dimensions.space.s8),
          DefaultTextStyle.merge(
            style: TextStyle(color: tint),
            child: LabelText(value),
          ),
        ],
      ),
    );
  }
}
