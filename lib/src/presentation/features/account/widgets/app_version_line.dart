import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/account_providers.dart';

/// "v 1.2.3" centred under the menu; blank until the platform answers.
class AppVersionLine extends ConsumerWidget {
  const AppVersionLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(accountAppVersionProvider).value;
    if (version == null || version.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.space.s8),
      child: Center(child: LabelText.muted(context.l10n.accVersion(version))),
    );
  }
}
