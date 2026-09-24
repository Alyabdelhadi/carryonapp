import 'dart:ui';

import 'package:flutter/material.dart';

import '../gen/assets.gen.dart';
import '../theme/theme.dart';
import 'svg_icon.dart';

/// One tab of the [GlassNavigationBar]: an outline icon at rest, the
/// filled variant when selected.
class GlassNavigationItem {
  const GlassNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final SvgGenImage icon;
  final SvgGenImage selectedIcon;
}

/// A floating, fully rounded frosted-glass tab bar. The scaffold behind it
/// must use `extendBody: true` so page content scrolls underneath and the
/// blur has something to frost.
class GlassNavigationBar extends StatelessWidget {
  const GlassNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<GlassNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _blurSigma = 18.0;
  static const _glassOpacity = 0.72;
  static const _edgeOpacity = 0.55;

  @override
  Widget build(BuildContext context) {
    final color = context.color;
    final dims = context.dimensions;
    final radius = BorderRadius.circular(dims.radius.full);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        dims.space.s16,
        dims.space.s8,
        dims.space.s16,
        dims.space.s8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: dims.elevation.raised,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.background.surface.withValues(
                  alpha: _glassOpacity,
                ),
                borderRadius: radius,
                border: Border.all(
                  color: color.background.surface.withValues(
                    alpha: _edgeOpacity,
                  ),
                  width: dims.border.xs,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: dims.space.s8,
                  vertical: dims.space.s4,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _GlassNavigationTab(
                          item: items[i],
                          selected: i == selectedIndex,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavigationTab extends StatelessWidget {
  const _GlassNavigationTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GlassNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _switchDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final color = context.color;
    final dims = context.dimensions;
    final iconColor = selected ? color.text.onPrimary : color.text.muted;
    final labelColor = selected ? color.text.strong : color.text.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dims.radius.large),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dims.space.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The icon sits on an ink pill when selected.
              AnimatedContainer(
                duration: _switchDuration,
                curve: Curves.easeOut,
                width: dims.size.touch + dims.space.s12,
                height: dims.size.iconLarge + dims.space.s8,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? color.primary.strong : Colors.transparent,
                  borderRadius: BorderRadius.circular(dims.radius.full),
                ),
                child: AnimatedSwitcher(
                  duration: _switchDuration,
                  child: SvgIcon(
                    key: ValueKey(selected),
                    selected ? item.selectedIcon : item.icon,
                    size: dims.size.iconLarge,
                    color: iconColor,
                  ),
                ),
              ),
              SizedBox(height: dims.space.s4),
              Text(
                item.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: context.textStyle.label.caption.copyWith(
                  color: labelColor,
                  fontWeight: selected ? FontWeight.w700 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
