import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/text/typography.dart';
import 'package_list_tile.dart';
import '../../../core/extensions/place_names_extension.dart';

/// One matching order for a carrier: category icon, reference, route,
/// needed-before date, reward, a NEW pill while unread and a "Carry" call
/// to action.
class MatchingPackageTile extends StatelessWidget {
  const MatchingPackageTile({
    super.key,
    required this.order,
    required this.onTap,
    required this.onCarry,
  });

  final ParcelOrder order;
  final VoidCallback onTap;
  final VoidCallback onCarry;

  bool get _isUnread => order.isRead == false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = context.dimensions.size.touch;
    final ref = l10n.pkwRefNumber('${order.id}');
    return SectionCard(
      onTap: onTap,
      margin: EdgeInsets.only(bottom: context.dimensions.space.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                file: order.categoryImage ?? '',
                kind: UploadKind.categories,
                width: size,
                height: size,
                borderRadius: BorderRadius.circular(
                  context.dimensions.radius.medium,
                ),
                fallbackIcon: Icons.inventory_2_outlined,
              ),
              Gap(context.dimensions.space.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _isUnread
                              ? LabelText(ref)
                              : BodySmallText.muted(ref),
                        ),
                        if (_isUnread)
                          TagChip(
                            label: l10n.pkwNewTag,
                            foreground: context.color.text.onPrimary,
                            background: context.color.primary.strong,
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
                    if (order.hasNeededBeforeDate)
                      BodySmallText.muted(
                        l10n.pkwNeededBeforeDate(
                          Formatters.monthDayYear(order.orderDate),
                        ),
                      )
                    else
                      BodySmallText.muted(l10n.pkwNeededSoon),
                    Gap(context.dimensions.space.s2),
                    BodySmallText.muted(
                      l10n.pkwRewardLine(
                        Formatters.reward(order.amount, free: l10n.free),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(context.dimensions.space.s12),
          Row(
            children: [
              if (order.categoryNameFor(context.languageCode) != null)
                TagChip(
                  label: order.categoryNameFor(context.languageCode)!,
                  icon: Icons.category_outlined,
                ),
              if (order.weight != null) ...[
                Gap(context.dimensions.space.s8),
                TagChip(label: order.weight!, icon: Icons.scale_outlined),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: onCarry,
                style: FilledButton.styleFrom(
                  minimumSize: Size(
                    context.dimensions.space.s80,
                    context.dimensions.size.iconDisplay,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.dimensions.space.s16,
                  ),
                ),
                icon: Icon(
                  Icons.flight_takeoff_rounded,
                  size: context.dimensions.size.iconSmall,
                ),
                label: Text(l10n.pkwCarry),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
