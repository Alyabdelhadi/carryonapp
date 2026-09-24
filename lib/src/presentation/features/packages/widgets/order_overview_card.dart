import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../../../core/extensions/place_names_extension.dart';

/// "Package Overview": dates, tracking number, type, reward, value, weight
/// and description.
class OrderOverviewCard extends StatelessWidget {
  const OrderOverviewCard({super.key, required this.order});

  final ParcelOrder order;

  String get _value {
    final v = (order.value ?? '').trim();
    if (v == 'less than \$100' || v == '< 100') return v;
    return '\$$v';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = context.dimensions.size.touch;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if ((order.categoryImage ?? '').isNotEmpty) ...[
                AppNetworkImage(
                  file: order.categoryImage,
                  kind: UploadKind.categories,
                  width: size,
                  height: size,
                  borderRadius: BorderRadius.circular(
                    context.dimensions.radius.medium,
                  ),
                  fallbackIcon: Icons.inventory_2_outlined,
                ),
                Gap(context.dimensions.space.s12),
              ],
              Expanded(child: HeadingLevel3Text(l10n.pkwPackageOverview)),
            ],
          ),
          Gap(context.dimensions.space.s12),
          OrderDetailLine(
            label: l10n.pkwRequestOn,
            value: Formatters.monthDayYear(order.createdAt),
          ),
          if (order.hasNeededBeforeDate)
            OrderDetailLine(
              label: l10n.pkwNeededBefore,
              value: Formatters.monthDayYear(order.orderDate),
            )
          else
            OrderDetailLine(label: l10n.pkwNeededSoon, value: l10n.pkwFlexible),
          OrderDetailLine(label: l10n.pkwTrackingNo, value: '${order.id}'),
          if (order.categoryNameFor(context.languageCode) != null)
            OrderDetailLine(
              label: l10n.pkwPackageType,
              value: order.categoryNameFor(context.languageCode)!,
            ),
          OrderDetailLine(
            label: l10n.pkwCarrierReward,
            value: Formatters.reward(order.amount, free: l10n.free),
          ),
          if ((order.value ?? '').trim().isNotEmpty)
            OrderDetailLine(label: l10n.pkwPackageValue, value: _value),
          if ((order.weight ?? '').trim().isNotEmpty)
            OrderDetailLine(label: l10n.pkwWeight, value: order.weight!),
          if ((order.description ?? '').trim().isNotEmpty)
            OrderDetailLine(
              label: l10n.pkwDescription,
              value: order.description!,
            ),
        ],
      ),
    );
  }
}

/// A label / value line of a detail card; the value can be tappable
/// (phone numbers, "Get Directions").
class OrderDetailLine extends StatelessWidget {
  const OrderDetailLine({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.icon,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;
    final valueText = Text(
      value,
      textAlign: TextAlign.end,
      style: context.textStyle.body.small.copyWith(
        color: interactive
            ? context.color.primary.strong
            : context.color.text.strong,
        fontWeight: FontWeight.w600,
        decoration: interactive ? TextDecoration.underline : null,
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.space.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: BodySmallText.muted(label)),
          Gap(context.dimensions.space.s8),
          Expanded(
            flex: 3,
            child: interactive
                ? InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(
                      context.dimensions.radius.small,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            size: context.dimensions.size.iconSmall,
                            color: context.color.primary.strong,
                          ),
                          Gap(context.dimensions.space.s4),
                        ],
                        Flexible(child: valueText),
                      ],
                    ),
                  )
                : valueText,
          ),
        ],
      ),
    );
  }
}
