import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';

/// The compact "1 Where & who — 2 What & how" strip under the app bar:
/// numbered dots joined by a rail, the current one filled, the finished
/// ones ticked. A finished step can be tapped to go back to it.
class OrderFormStepIndicator extends StatelessWidget {
  const OrderFormStepIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
    this.onStepTap,
  });

  final List<String> steps;
  final int currentStep;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.color.background.surface,
      padding: EdgeInsets.symmetric(
        horizontal: context.dimensions.space.s16,
        vertical: context.dimensions.space.s12,
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) ...[
              Gap(context.dimensions.space.s8),
              Expanded(
                child: Container(
                  height: context.dimensions.border.lg,
                  decoration: BoxDecoration(
                    color: i <= currentStep
                        ? context.color.primary.strong
                        : context.color.border.defaultValue,
                    borderRadius: BorderRadius.circular(
                      context.dimensions.radius.full,
                    ),
                  ),
                ),
              ),
              Gap(context.dimensions.space.s8),
            ],
            _Step(
              index: i,
              label: steps[i],
              done: i < currentStep,
              active: i == currentStep,
              onTap: i < currentStep && onStepTap != null
                  ? () => onStepTap!(i)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.label,
    required this.done,
    required this.active,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool done;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final highlighted = done || active;
    final dotColor = highlighted
        ? context.color.primary.strong
        : context.color.border.subtle;
    final onDot = highlighted
        ? context.color.text.onPrimary
        : context.color.text.muted;
    final labelStyle = active
        ? context.textStyle.label.strong.copyWith(
            color: context.color.text.strong,
          )
        : context.textStyle.label.regular.copyWith(
            color: context.color.text.muted,
          );
    final radius = BorderRadius.circular(context.dimensions.radius.full);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.dimensions.space.s4,
            vertical: context.dimensions.space.s2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.dimensions.size.iconLarge,
                height: context.dimensions.size.iconLarge,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
                child: done
                    ? Icon(
                        Icons.check_rounded,
                        size: context.dimensions.size.iconSmall,
                        color: onDot,
                      )
                    : Text(
                        '${index + 1}',
                        style: context.textStyle.label.caption.copyWith(
                          color: onDot,
                        ),
                      ),
              ),
              Gap(context.dimensions.space.s8),
              Text(label, style: labelStyle),
            ],
          ),
        ),
      ),
    );
  }
}
