import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/text/typography.dart';
import 'location_picker_map.dart';
import 'place_search_field.dart';

/// The full-height "drop the pin" mode of the address form: a place
/// search on top, the pannable map below it, and Cancel / Confirm at the
/// bottom. Until a first fix exists the map area shows a spinner.
class MapFullscreenPicker extends StatelessWidget {
  const MapFullscreenPicker({
    super.key,
    required this.lat,
    required this.lng,
    required this.locating,
    required this.onMapCreated,
    required this.onCameraMove,
    required this.onPlaceSelected,
    required this.onLocateMe,
    required this.onCancel,
    required this.onConfirm,
  });

  final double? lat;
  final double? lng;
  final bool locating;
  final void Function(GoogleMapController controller) onMapCreated;
  final void Function(CameraPosition position) onCameraMove;
  final void Function(PlaceInfo place) onPlaceSelected;
  final VoidCallback onLocateMe;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    final l10n = context.l10n;
    final hasFix = lat != null && lng != null;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            space.s16,
            space.s12,
            space.s16,
            context.dimensions.layout.none,
          ),
          child: PlaceSearchField(onSelected: onPlaceSelected),
        ),
        Gap(space.s12),
        Expanded(
          child: Stack(
            children: [
              if (hasFix)
                LocationPickerMap(
                  lat: lat!,
                  lng: lng!,
                  onMapCreated: onMapCreated,
                  onCameraMove: onCameraMove,
                )
              else
                ColoredBox(
                  color: context.color.background.canvas,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LoadingIndicator(),
                        Gap(space.s12),
                        BodySmallText.muted(l10n.accFindingLocation),
                      ],
                    ),
                  ),
                ),
              PositionedDirectional(
                end: space.s16,
                bottom: space.s16,
                child: FloatingActionButton.small(
                  heroTag: null,
                  onPressed: locating ? null : onLocateMe,
                  backgroundColor: context.color.background.surface,
                  foregroundColor: context.color.primary.strong,
                  tooltip: l10n.accLocateMe,
                  child: locating
                      ? const LoadingIndicator()
                      : const Icon(Icons.my_location_rounded),
                ),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.color.background.surface,
            boxShadow: context.dimensions.elevation.navigation,
          ),
          child: SafeArea(
            top: false,
            minimum: EdgeInsets.all(space.s16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                    label: Text(l10n.cancel),
                  ),
                ),
                Gap(space.s12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: hasFix ? onConfirm : null,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.confirm),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
