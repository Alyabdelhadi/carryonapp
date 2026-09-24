import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/text/typography.dart';
import 'order_form_section_card.dart';

/// The side of the exchange that is the signed-in user. The Ionic form
/// filled this silently from `localStorage` (`user_name`, `phone`); here
/// it is shown read-only so the user sees what will be sent.
class OrderFormSelfCard extends StatelessWidget {
  const OrderFormSelfCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.user,
  });

  final String title;
  final String subtitle;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return OrderFormSectionCard(
      icon: Icons.account_circle_outlined,
      title: title,
      subtitle: subtitle,
      trailing: TagChip(
        label: context.l10n.pkwYou,
        icon: Icons.check_rounded,
        foreground: context.color.accent.ecoStrong,
        background: context.color.accent.ecoTint,
      ),
      child: Row(
        children: [
          UserAvatar(
            initials: Formatters.initials(user.name),
            selfie: user.selfie,
          ),
          Gap(context.dimensions.space.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BodySmallText(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(context.dimensions.space.s2),
                BodySmallText.muted(
                  user.phone.isEmpty
                      ? context.l10n.pkwNoPhoneOnProfile
                      : user.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: user.phone.isEmpty ? null : TextDirection.ltr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
