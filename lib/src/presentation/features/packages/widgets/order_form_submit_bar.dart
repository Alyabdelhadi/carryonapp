import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/loading_indicator.dart';

/// The sticky bottom bar with the primary submit button and its loading
/// state (the Ionic `makeOrder` button with the crescent spinner). With
/// [secondaryLabel] an outlined action ("Back") sits beside it.
class OrderFormSubmitBar extends StatelessWidget {
  const OrderFormSubmitBar({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final primary = FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading ? const LoadingIndicator() : Text(label),
    );
    return Container(
      decoration: BoxDecoration(
        color: context.color.background.surface,
        boxShadow: context.dimensions.elevation.navigation,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(context.dimensions.space.s16),
          child: SizedBox(
            height: context.dimensions.size.control,
            child: secondaryLabel == null
                ? primary
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading ? null : onSecondaryPressed,
                          child: Text(secondaryLabel!),
                        ),
                      ),
                      Gap(context.dimensions.space.s12),
                      Expanded(flex: 2, child: primary),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
