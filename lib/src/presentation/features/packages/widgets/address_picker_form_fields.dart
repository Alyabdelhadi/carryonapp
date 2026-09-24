import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';

/// The address detail fields of the picker. Address name, street,
/// building and apartment were `required` in the Ionic form; notes and
/// the "save for future" checkbox are optional.
class AddressPickerFormFields extends StatelessWidget {
  const AddressPickerFormFields({
    super.key,
    required this.nameController,
    required this.streetController,
    required this.buildingController,
    required this.apartmentController,
    required this.notesController,
    required this.save,
    required this.onSaveChanged,
  });

  final TextEditingController nameController;
  final TextEditingController streetController;
  final TextEditingController buildingController;
  final TextEditingController apartmentController;
  final TextEditingController notesController;
  final bool save;
  final ValueChanged<bool> onSaveChanged;

  static String? _required(BuildContext context, String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.pkwFieldRequired(label);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gap = Gap(context.dimensions.space.s12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: nameController,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          validator: (v) => _required(context, l10n.pkwAddressNameHint, v),
          decoration: InputDecoration(
            hintText: l10n.pkwAddressNameHint,
            prefixIcon: const Icon(Icons.label_outline_rounded),
          ),
        ),
        gap,
        TextFormField(
          controller: streetController,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          validator: (v) => _required(context, l10n.pkwStreetHint, v),
          decoration: InputDecoration(
            hintText: l10n.pkwStreetHint,
            prefixIcon: const Icon(Icons.signpost_outlined),
          ),
        ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: buildingController,
                textInputAction: TextInputAction.next,
                validator: (v) => _required(context, l10n.pkwBuildingHint, v),
                decoration: InputDecoration(
                  hintText: l10n.pkwBuildingHint,
                  prefixIcon: const Icon(Icons.apartment_outlined),
                ),
              ),
            ),
            gap,
            Expanded(
              child: TextFormField(
                controller: apartmentController,
                textInputAction: TextInputAction.next,
                validator: (v) => _required(context, l10n.pkwApartmentHint, v),
                decoration: InputDecoration(
                  hintText: l10n.pkwApartmentHint,
                  prefixIcon: const Icon(Icons.door_front_door_outlined),
                ),
              ),
            ),
          ],
        ),
        gap,
        TextFormField(
          controller: notesController,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.pkwNotesHint,
            prefixIcon: const Icon(Icons.notes_rounded),
          ),
        ),
        Gap(context.dimensions.space.s4),
        CheckboxListTile(
          value: save,
          onChanged: (v) => onSaveChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: BodySmallText(l10n.pkwSaveAddressForFuture),
        ),
      ],
    );
  }
}
