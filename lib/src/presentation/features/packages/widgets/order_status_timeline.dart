import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/extensions/localized_labels.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/text/typography.dart';

/// The "status road": Start → Pickup → Transit → Delivered as a vertical
/// timeline, with the reached steps in the success colour. Cancelled and
/// expired orders show the badge and a note instead of progress.
class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.order, this.action});

  final ParcelOrder order;

  /// Optional trailing control (the carrier's "Change Status" button).
  final Widget? action;

  int get _reached => switch (order.status) {
    .delivered => 3,
    .transit => 2,
    .picked => 1,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [
      (
        Icons.hourglass_top_rounded,
        l10n.pkwTimelineStart,
        l10n.pkwTimelineStartHint,
      ),
      (
        Icons.inventory_2_outlined,
        ParcelOrderStatus.picked.label(l10n),
        l10n.pkwTimelinePickupHint,
      ),
      (
        Icons.flight_takeoff_rounded,
        ParcelOrderStatus.transit.label(l10n),
        l10n.pkwTimelineTransitHint,
      ),
      (
        Icons.check_circle_outline_rounded,
        ParcelOrderStatus.delivered.label(l10n),
        l10n.pkwTimelineDeliveredHint,
      ),
    ];
    final stopped = order.status.isFinal && order.status != .delivered;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: HeadingLevel3Text(l10n.pkwPackageStatus)),
              StatusBadge(
                status: order.status,
                label: order.status.label(l10n),
              ),
            ],
          ),
          Gap(context.dimensions.space.s16),
          for (var i = 0; i < steps.length; i++)
            OrderTimelineStep(
              icon: steps[i].$1,
              label: steps[i].$2,
              hint: steps[i].$3,
              reached: i <= _reached && !stopped,
              current: i == _reached && !stopped,
              isLast: i == steps.length - 1,
            ),
          if (stopped) ...[
            Gap(context.dimensions.space.s8),
            BodySmallText.muted(
              order.status == .cancelled
                  ? l10n.pkwPackageCancelledNote
                  : l10n.pkwPackageExpiredNote,
            ),
          ],
          if (action != null) ...[Gap(context.dimensions.space.s16), action!],
        ],
      ),
    );
  }
}

class OrderTimelineStep extends StatelessWidget {
  const OrderTimelineStep({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.reached,
    required this.current,
    required this.isLast,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool reached;
  final bool current;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final dot = context.dimensions.size.touch;
    final fg = reached ? c.text.onPrimary : c.text.muted;
    final bg = reached ? c.status.success : c.border.subtle;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: current
                      ? Border.all(
                          color: c.status.successTint,
                          width: context.dimensions.border.lg,
                        )
                      : null,
                ),
                child: Icon(
                  icon,
                  color: fg,
                  size: context.dimensions.size.iconMedium,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: context.dimensions.border.lg,
                    color: reached && !current
                        ? c.status.success
                        : c.border.subtle,
                  ),
                ),
            ],
          ),
          Gap(context.dimensions.space.s12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: context.dimensions.space.s8,
                bottom: isLast
                    ? context.dimensions.space.s4
                    : context.dimensions.space.s20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textStyle.label.strong.copyWith(
                      color: reached ? c.status.success : c.text.muted,
                    ),
                  ),
                  BodySmallText.muted(hint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
