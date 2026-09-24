import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/text/typography.dart';

/// The `tipBtn` / `tipActiveBtn` pill of the Ionic form: ink-black when
/// selected, a subtle grey otherwise. [imageFile] adds the category icon
/// (an `upload/categories/` file name) in front of the label.
class OrderFormChoiceChip extends StatelessWidget {
  const OrderFormChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.imageFile,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? imageFile;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.dimensions.radius.full);
    final foreground = selected
        ? context.color.text.onPrimary
        : context.color.text.defaultValue;
    return Material(
      color: selected
          ? context.color.primary.strong
          : context.color.border.subtle,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.dimensions.space.s16,
            vertical: context.dimensions.space.s8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageFile != null && imageFile!.trim().isNotEmpty) ...[
                AppNetworkImage(
                  file: imageFile,
                  kind: UploadKind.categories,
                  width: context.dimensions.size.iconLarge,
                  height: context.dimensions.size.iconLarge,
                  borderRadius: radius,
                  fallbackIcon: Icons.inventory_2_outlined,
                ),
                Gap(context.dimensions.space.s8),
              ],
              DefaultTextStyle.merge(
                style: TextStyle(color: foreground),
                child: LabelText(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A wrapping row of [OrderFormChoiceChip]s for a list of string options.
class OrderFormChipGroup extends StatelessWidget {
  const OrderFormChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.labelOf,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  /// How an option reads on its chip; defaults to the option itself.
  final String Function(String option)? labelOf;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.dimensions.space.s8,
      runSpacing: context.dimensions.space.s8,
      children: [
        for (final option in options)
          OrderFormChoiceChip(
            label: labelOf?.call(option) ?? option,
            selected: option == selected,
            onTap: () => onSelect(option),
          ),
      ],
    );
  }
}
