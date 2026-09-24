import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../../../core/extensions/place_names_extension.dart';

/// The "Pickup From" / "Carry To" block at the top of the Ionic form: two
/// read-only rows that open the address picker, joined by the up / down
/// arrow rail. When both ends are known it also shows the distance and
/// the CO2 estimate shortcut (the Ionic `OfferPage` modal).
class OrderFormRouteCard extends StatelessWidget {
  const OrderFormRouteCard({
    super.key,
    required this.sender,
    required this.receiver,
    required this.onPickSender,
    required this.onPickReceiver,
    required this.onCarbonEstimate,
    this.distanceKm,
  });

  final OrderAddress? sender;
  final OrderAddress? receiver;
  final VoidCallback onPickSender;
  final VoidCallback onPickReceiver;
  final VoidCallback onCarbonEstimate;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final complete = sender != null && receiver != null;
    return SectionCard(
      margin: EdgeInsets.only(bottom: context.dimensions.space.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _RouteRail(),
                Gap(context.dimensions.space.s12),
                Expanded(
                  child: Column(
                    children: [
                      _AddressTile(
                        placeholder: l10n.pkwPickupFrom,
                        address: sender,
                        onTap: onPickSender,
                      ),
                      Gap(context.dimensions.space.s8),
                      _AddressTile(
                        placeholder: l10n.pkwCarryTo,
                        address: receiver,
                        onTap: onPickReceiver,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (complete) ...[
            Gap(context.dimensions.space.s12),
            Row(
              children: [
                Icon(
                  Icons.route_outlined,
                  size: context.dimensions.size.iconMedium,
                  color: context.color.text.muted,
                ),
                Gap(context.dimensions.space.s4),
                Expanded(
                  child: BodySmallText.muted(
                    distanceKm == null
                        ? l10n.pkwDistanceUnavailable
                        : Formatters.distanceKm(distanceKm, unit: l10n.kmUnit),
                  ),
                ),
                TextButton.icon(
                  onPressed: onCarbonEstimate,
                  style: TextButton.styleFrom(
                    foregroundColor: context.color.accent.ecoStrong,
                  ),
                  icon: const Icon(Icons.eco_outlined),
                  label: Text(l10n.pkwCo2Impact),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The vertical up-arrow / dots / down-arrow ornament beside the rows.
class _RouteRail extends StatelessWidget {
  const _RouteRail();

  @override
  Widget build(BuildContext context) {
    final eco = context.color.accent.eco;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(
          Icons.arrow_circle_up_rounded,
          color: eco,
          size: context.dimensions.size.iconLarge,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: context.dimensions.layout.bullet,
                  height: context.dimensions.layout.bullet,
                  margin: EdgeInsets.symmetric(
                    vertical: context.dimensions.space.s2,
                  ),
                  decoration: BoxDecoration(
                    color: context.color.accent.ecoSoft,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_circle_down_rounded,
          color: eco,
          size: context.dimensions.size.iconLarge,
        ),
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.placeholder,
    required this.address,
    required this.onTap,
  });

  final String placeholder;
  final OrderAddress? address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.dimensions.radius.medium);
    final filled = address != null;
    return Material(
      color: context.color.background.canvas,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.dimensions.space.s12,
            vertical: context.dimensions.space.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabelText.muted(placeholder),
                    if (filled) ...[
                      Gap(context.dimensions.space.s2),
                      BodySmallText(
                        address!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (address!.summaryFor(context.languageCode) !=
                          address!.name)
                        BodySmallText.muted(
                          address!.summaryFor(context.languageCode),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ] else
                      BodySmallText.muted(context.l10n.pkwTapToChooseAddress),
                  ],
                ),
              ),
              Icon(
                filled
                    ? Icons.edit_location_alt_outlined
                    : Icons.add_location_alt_outlined,
                color: context.color.text.muted,
                size: context.dimensions.size.iconMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
