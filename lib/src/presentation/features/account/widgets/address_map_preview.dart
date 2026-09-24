import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import 'location_picker_map.dart';

/// The still map card at the top of the address form, with the resolved
/// "City, Country" line under it. Tapping the map or the expand button
/// opens the full picker; "Locate me" re-centres on the device.
class AddressMapPreview extends StatelessWidget {
  const AddressMapPreview({
    super.key,
    required this.lat,
    required this.lng,
    required this.city,
    required this.country,
    required this.locating,
    required this.geocoding,
    required this.onExpand,
    required this.onLocateMe,
  });

  final double? lat;
  final double? lng;
  final String city;
  final String country;
  final bool locating;
  final bool geocoding;
  final VoidCallback onExpand;
  final VoidCallback onLocateMe;

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    final l10n = context.l10n;
    final hasFix = lat != null && lng != null;
    final place = [city, country].where((p) => p.trim().isNotEmpty).join(', ');

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: context.dimensions.layout.logo,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasFix)
                  // The preview is a still image of the spot; the real
                  // panning happens in the full-screen picker.
                  LocationPickerMap(lat: lat!, lng: lng!, interactive: false)
                else
                  ColoredBox(
                    color: context.color.background.canvas,
                    child: Center(
                      child: locating
                          ? const LoadingIndicator()
                          : Icon(
                              Icons.map_outlined,
                              size: context.dimensions.size.iconDisplay,
                              color: context.color.text.muted,
                            ),
                    ),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onExpand),
                ),
                PositionedDirectional(
                  end: space.s12,
                  top: space.s12,
                  child: FloatingActionButton.small(
                    heroTag: null,
                    onPressed: onExpand,
                    backgroundColor: context.color.background.surface,
                    foregroundColor: context.color.primary.strong,
                    tooltip: l10n.accExpandMap,
                    child: const Icon(Icons.open_in_full_rounded),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              space.s16,
              space.s12,
              space.s8,
              context.dimensions.layout.none,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: context.dimensions.size.iconMedium,
                  color: context.color.accent.eco,
                ),
                Gap(space.s8),
                Expanded(
                  child: geocoding
                      ? BodySmallText.muted(l10n.accResolvingAddress)
                      : BodySmallText(
                          place.isEmpty ? l10n.accMovePinHint : place,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                TextButton.icon(
                  onPressed: locating ? null : onLocateMe,
                  icon: const Icon(Icons.my_location_rounded),
                  label: Text(l10n.accLocateMe),
                ),
              ],
            ),
          ),
          Gap(space.s8),
        ],
      ),
    );
  }
}
