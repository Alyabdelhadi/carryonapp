import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';

/// Flat placeholder blocks in the shape of the loaded content: the banner,
/// the section title and the three service cards (the skeleton the
/// original page showed while `data` was still null).
class HomeLoadingPlaceholder extends StatelessWidget {
  const HomeLoadingPlaceholder({
    super.key,
    this.showBanner = true,
    this.showServices = true,
  });

  /// Draws the banner block.
  final bool showBanner;

  /// Draws the title line and the three service card blocks.
  final bool showServices;

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBanner) ...[
          const _PlaceholderBlock(aspectRatio: 16 / 9),
          Gap(space.s24),
        ],
        if (showServices) ...[
          FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 0.6,
            child: SizedBox(
              height: context.dimensions.size.iconLarge,
              child: const _PlaceholderBlock(),
            ),
          ),
          Gap(space.s16),
          for (var i = 0; i < 3; i++) ...[
            const _PlaceholderBlock(aspectRatio: 2.4),
            Gap(space.s12),
          ],
        ],
      ],
    );
  }
}

class _PlaceholderBlock extends StatelessWidget {
  const _PlaceholderBlock({this.aspectRatio});

  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: context.color.border.subtle,
        borderRadius: BorderRadius.circular(context.dimensions.radius.large),
      ),
    );
    if (aspectRatio == null) return box;
    return AspectRatio(aspectRatio: aspectRatio!, child: box);
  }
}
