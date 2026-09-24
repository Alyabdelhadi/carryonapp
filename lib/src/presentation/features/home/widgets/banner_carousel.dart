import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/extensions/place_names_extension.dart';

/// An autoplaying banner row (3 s per slide, like the Bootstrap carousel
/// the original page used) with optional dot indicators over the image.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.images,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.cover,
    this.showIndicators = true,
  });

  final List<SliderImage> images;
  final double aspectRatio;
  final BoxFit fit;
  final bool showIndicators;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  static const _interval = Duration(seconds: 3);
  static const _slideDuration = Duration(milliseconds: 500);

  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startAutoplay();
  }

  @override
  void didUpdateWidget(BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length) {
      _page = 0;
      _startAutoplay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoplay() {
    _timer?.cancel();
    if (widget.images.length < 2) return;
    _timer = Timer.periodic(_interval, (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % widget.images.length;
      _controller.animateToPage(
        next,
        duration: _slideDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.dimensions.radius.large);
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.background.surface,
          borderRadius: radius,
          boxShadow: context.dimensions.elevation.card,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.images.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => AppNetworkImage(
                  file: widget.images[index].imageFor(context.languageCode),
                  kind: UploadKind.sliders,
                  fit: widget.fit,
                ),
              ),
              if (widget.showIndicators && widget.images.length > 1)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: context.dimensions.space.s12,
                  child: _DotIndicators(
                    count: widget.images.length,
                    active: _page,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotIndicators extends StatelessWidget {
  const _DotIndicators({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final dot = context.dimensions.layout.dot;
    final activeColor = context.color.background.surface;
    final idleColor = activeColor.withValues(alpha: 0.5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(
              horizontal: context.dimensions.space.s2,
            ),
            width: i == active ? dot * 2 : dot,
            height: dot,
            decoration: BoxDecoration(
              color: i == active ? activeColor : idleColor,
              borderRadius: BorderRadius.circular(
                context.dimensions.radius.full,
              ),
            ),
          ),
      ],
    );
  }
}
