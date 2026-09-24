import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';
import 'address_picker_pin.dart';

/// The small, non-interactive map above the address form. Tapping it (or
/// the expand button) opens the full-screen picker. When the map cannot
/// render on this platform a plain card with the coordinates stands in.
class AddressPickerMapPreview extends StatefulWidget {
  const AddressPickerMapPreview({
    super.key,
    required this.point,
    required this.canRenderMap,
    required this.onExpand,
  });

  final GeoPoint? point;
  final bool canRenderMap;
  final VoidCallback onExpand;

  static const double zoom = 16;

  @override
  State<AddressPickerMapPreview> createState() =>
      _AddressPickerMapPreviewState();
}

class _AddressPickerMapPreviewState extends State<AddressPickerMapPreview> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant AddressPickerMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final point = widget.point;
    if (point == null) return;
    final old = oldWidget.point;
    if (old?.lat != point.lat || old?.lng != point.lng) {
      _controller?.moveCamera(
        CameraUpdate.newLatLng(LatLng(point.lat, point.lng)),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.point;
    final radius = BorderRadius.circular(context.dimensions.radius.large);
    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: 2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.canRenderMap && point != null)
              IgnorePointer(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(point.lat, point.lng),
                    zoom: AddressPickerMapPreview.zoom,
                  ),
                  onMapCreated: (c) => _controller = c,
                  liteModeEnabled: true,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                ),
              )
            else
              _MapFallback(point: point),
            if (widget.canRenderMap && point != null)
              const AddressPickerPin(large: false),
            Material(
              color: Colors.transparent,
              child: InkWell(onTap: widget.onExpand),
            ),
            PositionedDirectional(
              top: context.dimensions.space.s8,
              end: context.dimensions.space.s8,
              child: Material(
                color: context.color.background.surface,
                borderRadius: BorderRadius.circular(
                  context.dimensions.radius.full,
                ),
                elevation: 0,
                child: IconButton(
                  tooltip: context.l10n.pkwExpandMap,
                  icon: const Icon(Icons.open_in_full_rounded),
                  onPressed: widget.onExpand,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.point});

  final GeoPoint? point;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.color.background.canvas,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: context.dimensions.size.iconDisplay,
              color: context.color.text.muted,
            ),
            Gap(context.dimensions.space.s8),
            BodySmallText.muted(
              point == null
                  ? context.l10n.pkwNoLocationYet
                  : '${point!.lat.toStringAsFixed(5)}, '
                        '${point!.lng.toStringAsFixed(5)}',
              textDirection: point == null ? null : TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}
