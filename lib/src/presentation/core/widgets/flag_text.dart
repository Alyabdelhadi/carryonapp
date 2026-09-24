import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A country's emoji flag, drawn large enough to read next to body text.
/// Emoji scale with the font size, so a caption-sized flag looks like a
/// speck; the display scale gives it the presence of an icon.
class FlagText extends StatelessWidget {
  const FlagText(this.flag, {super.key});

  final String? flag;

  @override
  Widget build(BuildContext context) {
    final value = flag ?? '';
    return SizedBox(
      width: context.dimensions.size.iconDisplay,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: context.textStyle.display.small.copyWith(height: 1),
      ),
    );
  }
}
