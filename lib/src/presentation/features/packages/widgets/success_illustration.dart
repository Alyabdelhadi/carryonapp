import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// The big tinted check (or cross) that stands in for the Ionic
/// `done.gif` / `cancel.gif`.
class SuccessIllustration extends StatelessWidget {
  const SuccessIllustration({super.key, required this.cancelled});

  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final tint = cancelled ? c.status.dangerTint : c.status.successTint;
    final fg = cancelled ? c.status.danger : c.status.success;
    final outer = context.dimensions.size.iconHero;
    final inner = outer - context.dimensions.space.s24;

    return Container(
      width: outer,
      height: outer,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
      child: Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
        child: Icon(
          cancelled ? Icons.close_rounded : Icons.check_rounded,
          color: c.text.onPrimary,
          size: context.dimensions.size.iconDisplay,
        ),
      ),
    );
  }
}
