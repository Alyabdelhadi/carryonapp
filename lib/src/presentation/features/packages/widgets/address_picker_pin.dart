import 'package:flutter/material.dart';

import '../../../core/gen/assets.gen.dart';
import '../../../core/theme/theme.dart';

/// The fixed pin drawn over the map centre (`assets/pin.png` in Ionic).
/// The camera moves under it; the pin never does.
class AddressPickerPin extends StatelessWidget {
  const AddressPickerPin({super.key, this.large = true});

  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large
        ? context.dimensions.size.control
        : context.dimensions.size.iconDisplay;
    return IgnorePointer(
      child: Center(
        child: Padding(
          // Lift the image so its tip sits on the exact centre.
          padding: EdgeInsets.only(bottom: size),
          child: Assets.images.pin.image(width: size, height: size),
        ),
      ),
    );
  }
}
