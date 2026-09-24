import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The 3D icons used by the figure strips (home stats, account stats).
/// The website's own set plus two Fluent 3D emoji (star, airplane) for the
/// figures the site does not have.
enum StatIcon {
  packages('assets/images/stats/packages.png'),
  users('assets/images/stats/users.png'),
  trees('assets/images/stats/trees.png'),
  cities('assets/images/stats/cities.png'),
  box('assets/images/stats/box.png'),
  star('assets/images/stats/star.png'),
  plane('assets/images/stats/plane.png');

  const StatIcon(this.asset);

  final String asset;
}

/// Renders a [StatIcon] at the display icon size.
class StatIconImage extends StatelessWidget {
  const StatIconImage(this.icon, {super.key});

  final StatIcon icon;

  @override
  Widget build(BuildContext context) {
    final size = context.dimensions.size.iconDisplay;
    return Image.asset(
      icon.asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    );
  }
}
