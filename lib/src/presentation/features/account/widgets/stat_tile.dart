import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';

/// One figure of the four-up stats strip: an icon in a tinted disc, the
/// number, and a caption. [eco] switches the disc to the impact green.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.eco = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool eco;

  @override
  Widget build(BuildContext context) {
    final color = context.color;
    final foreground = eco ? color.accent.eco : color.primary.strong;
    final background = eco ? color.accent.ecoTint : color.primary.tint;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.dimensions.size.touch,
          height: context.dimensions.size.touch,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(
            icon,
            color: foreground,
            size: context.dimensions.size.iconLarge,
          ),
        ),
        Gap(context.dimensions.space.s8),
        HeadingLevel3Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        LabelText.muted(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

/// The rating / packages / trips / trees strip on one card.
class StatsStrip extends StatelessWidget {
  const StatsStrip({super.key, required this.tiles});

  final List<StatTile> tiles;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.symmetric(
        vertical: context.dimensions.space.s16,
        horizontal: context.dimensions.space.s8,
      ),
      child: Row(children: [for (final tile in tiles) Expanded(child: tile)]),
    );
  }
}
