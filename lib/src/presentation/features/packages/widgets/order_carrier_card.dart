import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import 'order_overview_card.dart';

/// "Carrier Details" on an order the current user posted: avatar, name,
/// rating, phone and — once delivered and not yet rated — "Rate Carrier".
class OrderCarrierCard extends StatelessWidget {
  const OrderCarrierCard({
    super.key,
    required this.order,
    required this.canRate,
    required this.onCall,
    required this.onRate,
  });

  final ParcelOrder order;
  final bool canRate;
  final ValueChanged<String> onCall;
  final VoidCallback onRate;

  String _ratingLine(BuildContext context) {
    final score = Formatters.compact(
      order.carrierAverageRating ?? 0,
      fractionDigits: 1,
    );
    final count = order.carrierRatingsCount;
    return count == null
        ? context.l10n.pkwRatingScore(score)
        : context.l10n.pkwRatingScoreWithCount(score, count);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = order.carrierName ?? '';
    final phone = (order.carrierPhone ?? '').trim();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeadingLevel3Text(l10n.pkwCarrierDetails),
          Gap(context.dimensions.space.s12),
          Row(
            children: [
              UserAvatar(
                initials: Formatters.initials(name),
                selfie: order.carrierSelfie,
                size: context.dimensions.size.control,
              ),
              Gap(context.dimensions.space.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabelText(name.isEmpty ? l10n.pkwCarrier : name),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: context.dimensions.size.iconSmall,
                          color: context.color.status.warning,
                        ),
                        Gap(context.dimensions.space.s4),
                        BodySmallText.muted(_ratingLine(context)),
                      ],
                    ),
                  ],
                ),
              ),
              if (canRate)
                OutlinedButton.icon(
                  onPressed: onRate,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(
                      context.dimensions.space.s80,
                      context.dimensions.size.iconDisplay,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.dimensions.space.s12,
                    ),
                  ),
                  icon: Icon(
                    Icons.star_outline_rounded,
                    size: context.dimensions.size.iconSmall,
                  ),
                  label: Text(l10n.pkwRate),
                ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            Gap(context.dimensions.space.s8),
            OrderDetailLine(
              label: l10n.pkwPhone,
              value: phone,
              icon: Icons.call_outlined,
              onTap: () => onCall(phone),
            ),
          ],
        ],
      ),
    );
  }
}
