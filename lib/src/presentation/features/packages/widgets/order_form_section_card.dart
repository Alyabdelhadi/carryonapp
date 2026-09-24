import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';

/// One step of the order form: an icon in a tinted circle, a title, an
/// optional subtitle and the step's controls underneath, all on one card.
class OrderFormSectionCard extends StatelessWidget {
  const OrderFormSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle == null
        ? null
        : BodySmallText.muted(subtitle!);
    return SectionCard(
      margin: EdgeInsets.only(bottom: context.dimensions.space.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: context.dimensions.size.touch,
                height: context.dimensions.size.touch,
                decoration: BoxDecoration(
                  color: context.color.primary.tint,
                  borderRadius: BorderRadius.circular(
                    context.dimensions.radius.medium,
                  ),
                ),
                child: Icon(
                  icon,
                  size: context.dimensions.size.iconLarge,
                  color: context.color.primary.strong,
                ),
              ),
              Gap(context.dimensions.space.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [HeadingLevel3Text(title), ?subtitleText],
                ),
              ),
              ?trailing,
            ],
          ),
          Gap(context.dimensions.space.s16),
          child,
        ],
      ),
    );
  }
}
