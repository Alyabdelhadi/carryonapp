import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/extensions/localized_labels.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/text/typography.dart';
import '../../../core/extensions/place_names_extension.dart';

/// One row of the Packages tab: category icon (or a status glyph once the
/// order is moving), tracking number, route, status line and reward.
class PackageListTile extends StatelessWidget {
  const PackageListTile({super.key, required this.order, required this.onTap});

  final ParcelOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      onTap: onTap,
      margin: EdgeInsets.only(bottom: context.dimensions.space.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PackageListLeading(order: order),
          Gap(context.dimensions.space.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: BodySmallText.muted(
                        l10n.pkwTrackingNumber('${order.id}'),
                      ),
                    ),
                    StatusBadge(
                      status: order.status,
                      label: order.status.label(l10n),
                    ),
                  ],
                ),
                Gap(context.dimensions.space.s4),
                PackageRouteLine(
                  from:
                      order.sender.cityFor(context.languageCode) ??
                      order.sender.countryFor(context.languageCode),
                  to:
                      order.receiver.cityFor(context.languageCode) ??
                      order.receiver.countryFor(context.languageCode),
                ),
                Gap(context.dimensions.space.s4),
                PackageStatusLine(order: order),
                Gap(context.dimensions.space.s2),
                BodySmallText.muted(
                  l10n.pkwRewardLine(
                    Formatters.reward(order.amount, free: l10n.free),
                  ),
                ),
              ],
            ),
          ),
          Gap(context.dimensions.space.s8),
          Icon(
            Icons.chevron_right_rounded,
            color: context.color.text.muted,
            size: context.dimensions.size.iconMedium,
          ),
        ],
      ),
    );
  }
}

/// The category image while the order waits for or has a carrier, and a
/// status glyph in the status colour afterwards (the Ionic app swapped in
/// `assets/img/<status>.png`).
class PackageListLeading extends StatelessWidget {
  const PackageListLeading({super.key, required this.order});

  final ParcelOrder order;

  @override
  Widget build(BuildContext context) {
    final size = context.dimensions.size.touch;
    final radius = BorderRadius.circular(context.dimensions.radius.medium);
    final showsCategory =
        order.status == ParcelOrderStatus.unassigned ||
        order.status == ParcelOrderStatus.assigned;

    if (showsCategory && (order.categoryImage ?? '').isNotEmpty) {
      return AppNetworkImage(
        file: order.categoryImage,
        kind: UploadKind.categories,
        width: size,
        height: size,
        borderRadius: radius,
        fallbackIcon: Icons.inventory_2_outlined,
      );
    }

    final colors = statusColors(context, order.status);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colors.background, borderRadius: radius),
      child: Icon(
        statusIcon(order.status),
        color: colors.foreground,
        size: context.dimensions.size.iconLarge,
      ),
    );
  }
}

/// The glyph that stands in for the Ionic status image.
IconData statusIcon(ParcelOrderStatus status) => switch (status) {
  .unassigned => Icons.inventory_2_outlined,
  .assigned => Icons.handshake_outlined,
  .picked => Icons.inventory_rounded,
  .transit => Icons.flight_takeoff_rounded,
  .delivered => Icons.check_circle_outline_rounded,
  .cancelled => Icons.cancel_outlined,
  .expired => Icons.timer_off_outlined,
  .unknown => Icons.help_outline_rounded,
};

/// "Beirut ⇄ Dubai" in bold. The Wrap follows the ambient direction, so in
/// Arabic the origin sits on the right and the glyph (symmetric) between.
class PackageRouteLine extends StatelessWidget {
  const PackageRouteLine({super.key, required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final style = context.textStyle.body.strong.copyWith(
      color: context.color.text.strong,
    );
    // A Wrap instead of a Row: long city names take a line each with the
    // arrow between them instead of being cut to "Mount Leba...".
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: context.dimensions.space.s8,
      runSpacing: context.dimensions.space.s2,
      children: [
        Text(from, style: style, maxLines: 2, overflow: TextOverflow.ellipsis),
        Icon(
          Icons.swap_horiz_rounded,
          size: context.dimensions.size.iconMedium,
          color: context.color.text.muted,
        ),
        Text(to, style: style, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

/// The per-status line under the route: "Delivered on Jun 24" in the
/// status colour, or the needed-before date while unassigned.
class PackageStatusLine extends StatelessWidget {
  const PackageStatusLine({super.key, required this.order});

  final ParcelOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final updated = Formatters.monthDay(order.updatedAt);
    final text = switch (order.status) {
      .delivered => l10n.pkwDeliveredOn(updated),
      .cancelled => l10n.pkwCancelledOn(updated),
      .expired => l10n.pkwExpiredOn(updated),
      .picked => l10n.pkwPickedUpOn(updated),
      .transit => l10n.pkwTransitOn(updated),
      .assigned => l10n.pkwMatchedOn(updated),
      _ =>
        order.hasNeededBeforeDate
            ? l10n.pkwNeededBeforeShort(Formatters.monthDay(order.orderDate))
            : l10n.pkwNeededSoon,
    };
    final color = switch (order.status) {
      .unassigned || .unknown => context.color.text.muted,
      final status => statusColors(context, status).foreground,
    };
    return Text(
      text,
      style: context.textStyle.label.regular.copyWith(color: color),
    );
  }
}
