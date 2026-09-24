import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';

/// What the reverse geocoder resolved for the pin ("Beirut, Lebanon"),
/// and the "use current location" action that keeps the form usable when
/// the map cannot be shown.
class AddressPickerLocationRow extends StatelessWidget {
  const AddressPickerLocationRow({
    super.key,
    required this.city,
    required this.country,
    required this.resolving,
    required this.locating,
    required this.onLocate,
  });

  final String? city;
  final String? country;
  final bool resolving;
  final bool locating;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final parts = [
      city,
      country,
    ].where((p) => p != null && p.trim().isNotEmpty).cast<String>();
    final label = resolving
        ? context.l10n.pkwResolvingLocation
        : parts.isEmpty
        ? context.l10n.pkwLocationNotResolved
        : parts.join(', ');
    return Row(
      children: [
        Icon(
          Icons.place_outlined,
          size: context.dimensions.size.iconMedium,
          color: context.color.accent.eco,
        ),
        Gap(context.dimensions.space.s8),
        Expanded(
          child: BodySmallText(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Gap(context.dimensions.space.s8),
        TextButton.icon(
          onPressed: locating ? null : onLocate,
          icon: locating
              ? SizedBox(
                  width: context.dimensions.size.iconSmall,
                  height: context.dimensions.size.iconSmall,
                  child: const CircularProgressIndicator(),
                )
              : const Icon(Icons.my_location_rounded),
          label: Text(context.l10n.pkwMyLocation),
        ),
      ],
    );
  }
}
