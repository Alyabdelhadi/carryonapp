import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/theme.dart';

/// The standard "nothing here yet" body: an icon, a title, optional copy
/// and an optional call to action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.dimensions.space.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.dimensions.size.iconHero,
              height: context.dimensions.size.iconHero,
              decoration: BoxDecoration(
                color: context.color.primary.tint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: context.dimensions.size.iconDisplay,
                color: context.color.primary.strong,
              ),
            ),
            Gap(context.dimensions.space.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textStyle.heading.level3.copyWith(
                color: context.color.text.strong,
              ),
            ),
            if (message != null) ...[
              Gap(context.dimensions.space.s8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.textStyle.body.small.copyWith(
                  color: context.color.text.muted,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              Gap(context.dimensions.space.s24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
