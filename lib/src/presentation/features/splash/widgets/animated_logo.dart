import 'package:flutter/material.dart';

import '../../../core/gen/assets.gen.dart';
import '../../../core/theme/theme.dart';

/// The RR mark on the launch screen: it fades and springs in from small,
/// then keeps a slow breathing pulse until the router moves on.
///
/// The entrance waits for the image to be decoded, so the animation is
/// never spent on an invisible frame.
class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  static const _entrance = Duration(milliseconds: 900);
  static const _breath = Duration(milliseconds: 1600);
  static const _startScale = 0.55;
  static const _breathScale = 1.04;

  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: _entrance,
  );
  late final AnimationController _breathController = AnimationController(
    vsync: this,
    duration: _breath,
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: _startScale, end: 1).animate(
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
      );
  late final Animation<double> _breathing =
      Tween<double>(begin: 1, end: _breathScale).animate(
        CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
      );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    precacheImage(Assets.images.logo.provider(), context).whenComplete(_play);
  }

  void _play() {
    if (!mounted) return;
    _entranceController.forward().whenComplete(() {
      if (mounted) _breathController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = context.dimensions.layout.logo;
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _breathController]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value * _breathing.value,
            child: child,
          ),
        );
      },
      child: Assets.images.logo.image(
        width: size,
        height: size,
        gaplessPlayback: true,
      ),
    );
  }
}
