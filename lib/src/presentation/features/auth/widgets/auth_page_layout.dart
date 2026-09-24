import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/gen/assets.gen.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';

/// The shared shell of the auth screens: the brand logo, a title and
/// subtitle, one card holding the form, and whatever follows the card
/// (secondary actions). Scrolls and keeps clear of the keyboard.
class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.title,
    required this.form,
    this.subtitle,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final Widget form;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(
            horizontal: space.s16,
            vertical: space.s24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.dimensions.breakpoint.mobile,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AuthHeader(title: title, subtitle: subtitle),
                Gap(space.s24),
                SectionCard(padding: EdgeInsets.all(space.s20), child: form),
                if (footer != null) ...[Gap(space.s24), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    return Column(
      children: [
        Assets.images.logo.image(
          height: context.dimensions.layout.logoSmall,
          fit: BoxFit.contain,
        ),
        Gap(space.s16),
        HeadingLevel1Text(title, textAlign: TextAlign.center),
        if (subtitle != null) ...[
          Gap(space.s8),
          BodySmallText.muted(subtitle!, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
