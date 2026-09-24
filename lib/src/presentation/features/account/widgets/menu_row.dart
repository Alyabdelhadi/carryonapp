import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';

/// A card holding a stack of [MenuRow]s separated by hairlines.
class MenuSection extends StatelessWidget {
  const MenuSection({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.space.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: context.dimensions.layout.hairline,
                thickness: context.dimensions.layout.hairline,
                indent: context.dimensions.space.s16,
                endIndent: context.dimensions.space.s16,
                color: context.color.border.subtle,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One tappable line of the account menu: leading icon, label and either
/// a chevron or a custom [trailing] control. [value] is a short muted text
/// shown before the chevron (the current language, say). [destructive]
/// paints the row in the danger colour for "Delete my account".
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.value,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? value;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? context.color.status.danger
        : context.color.text.defaultValue;
    final value = this.value;

    final Widget? chevron = onTap == null
        ? null
        : Icon(
            Icons.chevron_right_rounded,
            color: context.color.text.muted,
            size: context.dimensions.size.iconLarge,
          );
    final Widget? end;
    if (trailing != null) {
      end = trailing;
    } else if (value == null) {
      end = chevron;
    } else {
      end = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LabelText.muted(value),
          if (chevron != null) ...[Gap(context.dimensions.space.s4), chevron],
        ],
      );
    }

    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: destructive ? color : context.color.text.muted,
        size: context.dimensions.size.iconLarge,
      ),
      title: LabelText(label),
      trailing: end,
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.dimensions.space.s16,
      ),
      minVerticalPadding: context.dimensions.space.s12,
      textColor: color,
    );
  }
}
