import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../core/gen/l10n/app_localizations.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/order_form_provider.dart';
import 'order_form_amount_field.dart';
import 'order_form_choice_chip.dart';
import 'order_form_section_card.dart';
import '../../../core/extensions/place_names_extension.dart';

/// "Package": type chips with the admin hint, description, the declared
/// value and the approximate weight, each a number field with quick picks.
class OrderFormPackageSection extends ConsumerWidget {
  const OrderFormPackageSection({
    super.key,
    required this.selectedCategoryId,
    required this.onCategory,
    required this.descriptionController,
    required this.valueController,
    required this.weightController,
    required this.weightPicks,
  });

  final int? selectedCategoryId;
  final ValueChanged<ParcelCategory> onCategory;
  final TextEditingController descriptionController;
  final TextEditingController valueController;
  final TextEditingController weightController;

  /// Weight quick picks in kg ("0.5", "2"), from the admin's Weights page.
  final List<String> weightPicks;

  /// The unit appended to the weight the API receives ("2 kg"); a wire
  /// value, so it is not localized. The field shows [AppLocalizations.kgUnit].
  static const String weightUnit = 'kg';
  static const List<String> valuePicks = ['50', '100', '250', '500'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(orderFormCategoriesProvider);
    return OrderFormSectionCard(
      icon: Icons.inventory_2_outlined,
      title: l10n.pkwPackage,
      subtitle: l10n.pkwPackageSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabelText(l10n.pkwPackageType),
          Gap(context.dimensions.space.s8),
          switch (categories) {
            AsyncData(:final value) => _CategoryChips(
              categories: value,
              selectedId: selectedCategoryId,
              onCategory: onCategory,
            ),
            AsyncError() => _InlineRetry(
              message: l10n.pkwPackageTypesLoadFailed,
              onRetry: () => ref.invalidate(orderFormCategoriesProvider),
            ),
            _ => const LinearProgressIndicator(),
          },
          Gap(context.dimensions.space.s12),
          TextField(
            controller: descriptionController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.pkwDescribePackageHint,
              prefixIcon: const Icon(Icons.edit_note_outlined),
            ),
          ),
          Gap(context.dimensions.space.s20),
          OrderFormAmountField(
            label: l10n.pkwPackageValue,
            hint: l10n.pkwPackageValue,
            controller: valueController,
            prefixText: r'$',
            quickPicks: valuePicks,
          ),
          Gap(context.dimensions.space.s20),
          OrderFormAmountField(
            label: l10n.pkwApproximateWeight,
            hint: l10n.pkwWeight,
            controller: weightController,
            suffixText: l10n.kgUnit,
            quickPicks: weightPicks,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onCategory,
  });

  final List<ParcelCategory> categories;
  final int? selectedId;
  final ValueChanged<ParcelCategory> onCategory;

  @override
  Widget build(BuildContext context) {
    ParcelCategory? selected;
    for (final c in categories) {
      if (c.id == selectedId) selected = c;
    }
    final hint = selected?.text?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: context.dimensions.space.s8,
          runSpacing: context.dimensions.space.s8,
          children: [
            for (final category in categories)
              OrderFormChoiceChip(
                label: category.nameFor(context.languageCode),
                imageFile: category.image,
                selected: category.id == selectedId,
                onTap: () => onCategory(category),
              ),
          ],
        ),
        if (hint != null && hint.isNotEmpty) ...[
          Gap(context.dimensions.space.s12),
          Container(
            padding: EdgeInsets.all(context.dimensions.space.s12),
            decoration: BoxDecoration(
              color: context.color.status.informationTint,
              borderRadius: BorderRadius.circular(
                context.dimensions.radius.medium,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: context.dimensions.size.iconMedium,
                  color: context.color.status.information,
                ),
                Gap(context.dimensions.space.s8),
                Expanded(child: BodySmallText(hint)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: BodySmallText.muted(message)),
        TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ],
    );
  }
}
