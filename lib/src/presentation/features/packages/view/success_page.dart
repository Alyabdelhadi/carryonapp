import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../core/gen/l10n/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../widgets/success_illustration.dart';

/// `/success/:type` (Ionic `success`): the confirmation after posting,
/// accepting or cancelling a package, with one button back to Packages.
class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key, required this.type});

  final SuccessType type;

  String _title(AppLocalizations l10n) => switch (type) {
    .orderPlaced || .packageAccepted => l10n.pkgSuccessAllDone,
    .orderCancelled => l10n.pkgSuccessCancelledTitle,
  };

  String _message(AppLocalizations l10n) => switch (type) {
    .orderPlaced => l10n.pkgSuccessPlacedMessage,
    .packageAccepted => l10n.pkgSuccessAcceptedMessage,
    .orderCancelled => l10n.pkgSuccessCancelledMessage,
  };

  String _hint(AppLocalizations l10n) => switch (type) {
    .orderPlaced => l10n.pkgSuccessPlacedHint,
    .packageAccepted => l10n.pkgSuccessAcceptedHint,
    .orderCancelled => l10n.pkgSuccessCancelledHint,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.goNamed(Routes.packages.name);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title(l10n)),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.dimensions.space.s24),
            child: Column(
              children: [
                const Spacer(),
                SuccessIllustration(cancelled: type == .orderCancelled),
                Gap(context.dimensions.space.s24),
                Text(
                  _message(l10n),
                  textAlign: TextAlign.center,
                  style: context.textStyle.heading.level2.copyWith(
                    color: context.color.text.strong,
                  ),
                ),
                Gap(context.dimensions.space.s8),
                Text(
                  _hint(l10n),
                  textAlign: TextAlign.center,
                  style: context.textStyle.body.small.copyWith(
                    color: context.color.text.muted,
                  ),
                ),
                const Spacer(flex: 2),
                FilledButton(
                  onPressed: () => context.goNamed(Routes.packages.name),
                  child: Text(l10n.continueLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
