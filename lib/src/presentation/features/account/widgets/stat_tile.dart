import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/stat_icon.dart';
import '../../../core/widgets/text/typography.dart';

/// One figure of the four-up stats strip: a 3D icon (same set as the home
/// stats), the number, and a caption.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final StatIcon icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatIconImage(icon),
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
