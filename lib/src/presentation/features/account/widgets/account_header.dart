import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../../../core/widgets/verified_badge.dart';

/// Avatar, name and contact lines at the top of the account tab. Tapping
/// anywhere opens the profile editor, as the original's header did.
class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key, required this.user, required this.onTap});

  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      padding: EdgeInsets.all(context.dimensions.space.s20),
      child: Row(
        children: [
          UserAvatar(
            initials: Formatters.initials(user.name),
            selfie: user.selfie,
            size: context.dimensions.layout.logoSmall * 0.72,
          ),
          Gap(context.dimensions.space.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeadingLevel3Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.isVerified) ...[
                  Gap(context.dimensions.space.s4),
                  VerifiedBadge(verified: user.isVerified),
                ],
                Gap(context.dimensions.space.s2),
                BodySmallText.muted(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.phone.trim().isNotEmpty)
                  BodySmallText.muted(
                    user.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Gap(context.dimensions.space.s8),
          Icon(
            Icons.chevron_right_rounded,
            color: context.color.text.muted,
            size: context.dimensions.size.iconLarge,
          ),
        ],
      ),
    );
  }
}
