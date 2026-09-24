import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/gen/assets.gen.dart';
import '../../../core/theme/theme.dart';

/// A Google map with the app's pin fixed at the centre: the user drags the
/// world under it and [onCameraMove] reports where the pin now points.
/// [interactive] false renders a still preview (a tap target that opens
/// the full picker) instead of a pannable map.
class LocationPickerMap extends StatelessWidget {
  const LocationPickerMap({
    super.key,
    required this.lat,
    required this.lng,
    this.interactive = true,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
  });

  static const double zoom = 16;

  final double lat;
  final double lng;
  final bool interactive;
  final void Function(GoogleMapController controller)? onMapCreated;
  final void Function(CameraPosition position)? onCameraMove;
  final VoidCallback? onCameraIdle;

  @override
  Widget build(BuildContext context) {
    final pinSize = context.dimensions.size.iconDisplay;

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: !interactive,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: zoom,
            ),
            onMapCreated: onMapCreated,
            onCameraMove: onCameraMove,
            onCameraIdle: onCameraIdle,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            rotateGesturesEnabled: interactive,
            scrollGesturesEnabled: interactive,
            zoomGesturesEnabled: interactive,
            tiltGesturesEnabled: false,
          ),
        ),
        IgnorePointer(
          child: Center(
            // The pin's tip, not its middle, marks the spot: lift it by
            // half its height.
            child: Transform.translate(
              offset: Offset(0, -pinSize / 2),
              child: Assets.images.pin.image(
                width: pinSize,
                height: pinSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
