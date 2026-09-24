import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';

/// The From / To city filters above the matching list. `null` means
/// "All Countries".
class MatchingFilterBar extends StatelessWidget {
  const MatchingFilterBar({
    super.key,
    required this.fromOptions,
    required this.toOptions,
    required this.selectedFrom,
    required this.selectedTo,
    required this.onFromChanged,
    required this.onToChanged,
  });

  final List<String> fromOptions;
  final List<String> toOptions;
  final String? selectedFrom;
  final String? selectedTo;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.dimensions.space.s16,
        context.dimensions.space.s8,
        context.dimensions.space.s16,
        context.dimensions.space.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: MatchingFilterDropdown(
              label: context.l10n.pkwFilterFrom,
              icon: Icons.trip_origin_rounded,
              options: fromOptions,
              value: selectedFrom,
              onChanged: onFromChanged,
            ),
          ),
          Gap(context.dimensions.space.s12),
          Expanded(
            child: MatchingFilterDropdown(
              label: context.l10n.pkwFilterTo,
              icon: Icons.location_on_outlined,
              options: toOptions,
              value: selectedTo,
              onChanged: onToChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class MatchingFilterDropdown extends StatelessWidget {
  const MatchingFilterDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      key: ValueKey('$label:${options.join('|')}'),
      initialValue: options.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: context.dimensions.size.iconMedium),
      ),
      items: [
        DropdownMenuItem<String?>(child: Text(context.l10n.pkwAllCountries)),
        for (final option in options)
          DropdownMenuItem<String?>(
            value: option,
            child: Text(option, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
