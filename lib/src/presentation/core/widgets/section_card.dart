import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/theme.dart';

/// A white rounded surface with the card shadow; the building block of
/// every list row and form section.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.dimensions.radius.large);
    final body = Padding(
      padding: padding ?? EdgeInsets.all(context.dimensions.space.s16),
      child: child,
    );
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? context.color.background.surface,
        borderRadius: radius,
        boxShadow: context.dimensions.elevation.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? body
            : InkWell(onTap: onTap, borderRadius: radius, child: body),
      ),
    );
  }
}

/// A heading above a group of cards, with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: context.textStyle.heading.level3.copyWith(
              color: context.color.text.strong,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// A label + value line used in detail screens.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.space.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: context.dimensions.size.iconMedium,
              color: context.color.text.muted,
            ),
            Gap(context.dimensions.space.s8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.textStyle.body.small.copyWith(
                color: context.color.text.muted,
              ),
            ),
          ),
          Gap(context.dimensions.space.s8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.textStyle.body.small.copyWith(
                color: valueColor ?? context.color.text.strong,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
