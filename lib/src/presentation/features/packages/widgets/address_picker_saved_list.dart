import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/address_picker_provider.dart';
import '../../../core/extensions/place_names_extension.dart';

/// The user's address book at the top of the picker: one tap fills the
/// whole form and moves the pin. Shows the first few and a "show all"
/// toggle for the rest. Renders nothing while loading, on failure, or
/// when the book is empty.
class AddressPickerSavedList extends ConsumerStatefulWidget {
  const AddressPickerSavedList({
    super.key,
    required this.userId,
    required this.selected,
    required this.onSelect,
  });

  final int userId;
  final Address? selected;
  final ValueChanged<Address> onSelect;

  @override
  ConsumerState<AddressPickerSavedList> createState() =>
      _AddressPickerSavedListState();
}

class _AddressPickerSavedListState
    extends ConsumerState<AddressPickerSavedList> {
  static const _collapsedCount = 3;

  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(
      addressPickerSavedAddressesProvider(widget.userId),
    );
    final space = context.dimensions.space;

    return switch (addresses) {
      AsyncData(:final value) when value.isNotEmpty => Padding(
        padding: EdgeInsets.only(bottom: space.s16),
        child: SectionCard(
          padding: EdgeInsets.symmetric(
            horizontal: space.s16,
            vertical: space.s12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bookmark_rounded,
                    size: context.dimensions.size.iconMedium,
                    color: context.color.primary.strong,
                  ),
                  Gap(space.s8),
                  Expanded(
                    child: HeadingLevel3Text(context.l10n.pkwSavedAddresses),
                  ),
                ],
              ),
              Gap(space.s4),
              for (final address
                  in _showAll ? value : value.take(_collapsedCount))
                _SavedAddressRow(
                  address: address,
                  selected: widget.selected?.id == address.id,
                  onTap: () => widget.onSelect(address),
                ),
              if (value.length > _collapsedCount)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(
                      _showAll
                          ? context.l10n.pkwShowFewer
                          : context.l10n.pkwShowAll(value.length),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _SavedAddressRow extends StatelessWidget {
  const _SavedAddressRow({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.color;
    final dims = context.dimensions;
    final radius = BorderRadius.circular(dims.radius.medium);

    return Padding(
      padding: EdgeInsets.only(top: dims.space.s8),
      child: Material(
        color: selected ? color.primary.tint : color.background.canvas,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dims.space.s12,
              vertical: dims.space.s12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: dims.size.iconMedium,
                  color: selected ? color.primary.strong : color.text.muted,
                ),
                Gap(dims.space.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BodySmallText(
                        address.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (address.summaryFor(context.languageCode).isNotEmpty)
                        BodySmallText.muted(
                          address.summaryFor(context.languageCode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Gap(dims.space.s8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  size: dims.size.iconMedium,
                  color: selected ? color.primary.strong : color.text.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
