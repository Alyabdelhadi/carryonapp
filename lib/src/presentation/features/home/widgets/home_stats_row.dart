import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/stat_icon.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/home_providers.dart';

/// The four counters from the website ("Shop • Travel • Earn"): packages,
/// users, trees saved and cities, each with its 3D icon and a count-up
/// animation. Hidden until the numbers arrive; hidden on error too, so a
/// missing endpoint never breaks the home screen.
class HomeStatsRow extends ConsumerWidget {
  const HomeStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(homeStatsProvider);
    return switch (stats) {
      AsyncData(:final value) => _StatsCard(stats: value),
      _ => const SizedBox.shrink(),
    };
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final HomeStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final space = context.dimensions.space;
    final items = [
      (StatIcon.packages, stats.packages, l10n.homeStatPackages),
      (StatIcon.users, stats.users, l10n.homeStatUsers),
      (StatIcon.trees, stats.treesSaved, l10n.homeStatTreesSaved),
      (StatIcon.cities, stats.cities, l10n.homeStatCities),
    ];
    return Container(
      padding: EdgeInsets.symmetric(vertical: space.s16, horizontal: space.s8),
      decoration: BoxDecoration(
        color: context.color.background.surface,
        borderRadius: BorderRadius.circular(context.dimensions.radius.large),
      ),
      child: Row(
        children: [
          for (final (icon, value, label) in items)
            Expanded(
              child: _StatTile(icon: icon, value: value, label: label),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final StatIcon icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatIconImage(icon),
        Gap(space.s8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) => HeadingLevel3Text(
            Formatters.count(animated.round()),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
        Gap(space.s2),
        BodySmallText.muted(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
