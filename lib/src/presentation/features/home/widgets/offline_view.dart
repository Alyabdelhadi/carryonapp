import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/gen/assets.gen.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';

/// The "no internet" body with the animated illustration and the refresh
/// button the original page showed while offline.
class OfflineView extends StatelessWidget {
  const OfflineView({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.dimensions.space.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                context.dimensions.radius.large,
              ),
              child: Assets.images.nointernet.image(fit: BoxFit.contain),
            ),
            Gap(context.dimensions.space.s24),
            HeadingLevel3Text(
              context.l10n.noInternet,
              textAlign: TextAlign.center,
            ),
            Gap(context.dimensions.space.s8),
            BodySmallText.muted(
              context.l10n.noInternetDescription,
              textAlign: TextAlign.center,
            ),
            Gap(context.dimensions.space.s24),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.homeRefreshPage),
            ),
          ],
        ),
      ),
    );
  }
}
