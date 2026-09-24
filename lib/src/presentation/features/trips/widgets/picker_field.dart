import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';

/// A tappable field that opens a picker: the Ionic "input-group" rows with
/// a placeholder, the chosen value and a trailing chevron.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.placeholder,
    required this.onTap,
    this.value,
    this.icon,
  });

  final String placeholder;
  final String? value;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.dimensions.radius.medium);
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Material(
      color: context.color.background.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            minHeight: context.dimensions.size.control,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: context.dimensions.space.s16,
            vertical: context.dimensions.space.s12,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: hasValue
                  ? context.color.border.defaultValue
                  : context.color.border.subtle,
              width: context.dimensions.border.xs,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: context.dimensions.size.iconMedium,
                  color: hasValue
                      ? context.color.primary.strong
                      : context.color.text.muted,
                ),
                Gap(context.dimensions.space.s12),
              ],
              Expanded(
                child: hasValue
                    ? LabelText(
                        value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : LabelText.muted(placeholder),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.color.text.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
