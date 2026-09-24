import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/home_providers.dart';

/// The hero greeting, the current location and — for carriers — the
/// package icon (red dot when packages match) and the airplane icon (badge
/// with the upcoming trips count).
class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    required this.onPackagesTap,
    required this.onTripsTap,
  });

  final VoidCallback onPackagesTap;
  final VoidCallback onTripsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isCarrier = ref.watch(isCarrierProvider);
    final place = ref.watch(homePlaceProvider).value;
    final hasMatches =
        ref.watch(homeHasMatchingPackagesProvider).value ?? false;
    final tripsCount = ref.watch(homeUpcomingTripsCountProvider).value ?? 0;

    final firstName = user?.firstName.trim();
    final l10n = context.l10n;
    final greeting = firstName == null || firstName.isEmpty
        ? l10n.homeGreetingGuest
        : l10n.homeGreeting(firstName);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeadingLevel1Text(greeting, maxLines: 2),
              if (place != null) ...[
                Gap(context.dimensions.space.s4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: context.dimensions.size.iconSmall,
                      color: context.color.text.muted,
                    ),
                    Gap(context.dimensions.space.s4),
                    Flexible(
                      child: LabelText.muted(
                        place.shortLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (isCarrier) ...[
          Gap(context.dimensions.space.s12),
          _HeaderAction(
            icon: Icons.inventory_2_rounded,
            tooltip: l10n.homeMatchingPackagesTooltip,
            onTap: onPackagesTap,
            showDot: hasMatches,
          ),
          Gap(context.dimensions.space.s8),
          _HeaderAction(
            icon: Icons.flight_rounded,
            tooltip: l10n.homeMyTripsTooltip,
            onTap: onTripsTap,
            count: tripsCount,
          ),
        ],
      ],
    );
  }
}

/// A round surface button. [showDot] draws the red dot; a positive
/// [count] draws the red counter badge instead.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.showDot = false,
    this.count = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool showDot;
  final int count;

  @override
  Widget build(BuildContext context) {
    final size = context.dimensions.size.touch;
    return Badge(
      isLabelVisible: showDot || count > 0,
      label: count > 0 ? Text('$count') : null,
      backgroundColor: context.color.status.danger,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.color.background.surface,
          shape: BoxShape.circle,
          boxShadow: context.dimensions.elevation.card,
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(
            icon,
            size: context.dimensions.size.iconMedium,
            color: context.color.text.strong,
          ),
        ),
      ),
    );
  }
}
