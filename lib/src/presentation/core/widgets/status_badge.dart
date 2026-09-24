import 'package:flutter/material.dart';

import '../../../core/extensions/localization.dart';
import '../../../domain/entities/parcel_order.dart';
import '../extensions/localized_labels.dart';
import '../theme/theme.dart';

/// The colour pair a parcel status renders in, resolved from the theme.
({Color foreground, Color background}) statusColors(
  BuildContext context,
  ParcelOrderStatus status,
) {
  final c = context.color;
  return switch (status) {
    .unassigned => (
      foreground: c.text.defaultValue,
      background: c.border.subtle,
    ),
    .assigned => (
      foreground: c.status.information,
      background: c.status.informationTint,
    ),
    .picked => (foreground: c.accent.picked, background: c.accent.pickedTint),
    .transit => (foreground: c.accent.sky, background: c.accent.skyTint),
    .delivered => (
      foreground: c.status.success,
      background: c.status.successTint,
    ),
    .cancelled => (
      foreground: c.status.danger,
      background: c.status.dangerTint,
    ),
    .expired => (foreground: c.text.muted, background: c.border.subtle),
    .unknown => (foreground: c.text.muted, background: c.border.subtle),
  };
}

/// A rounded pill with the status colour.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.label});

  final ParcelOrderStatus status;

  /// Overrides the default localized status label.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = statusColors(context, status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dimensions.space.s8,
        vertical: context.dimensions.space.s2,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(context.dimensions.radius.full),
      ),
      child: Text(
        label ?? status.label(context.l10n),
        style: context.textStyle.label.caption.copyWith(
          color: colors.foreground,
        ),
      ),
    );
  }
}

/// A small tinted pill for any short tag ("Daily", "One-time").
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.icon,
    this.foreground,
    this.background,
  });

  final String label;
  final IconData? icon;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? context.color.text.defaultValue;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dimensions.space.s8,
        vertical: context.dimensions.space.s4,
      ),
      decoration: BoxDecoration(
        color: background ?? context.color.border.subtle,
        borderRadius: BorderRadius.circular(context.dimensions.radius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: context.dimensions.size.iconSmall, color: fg),
            SizedBox(width: context.dimensions.space.s4),
          ],
          Text(
            label,
            style: context.textStyle.label.caption.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
