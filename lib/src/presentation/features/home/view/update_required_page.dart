import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/gen/assets.gen.dart';
import '../../../../data/services/network/endpoints.dart';
import '../../../core/application_state/app_gate_provider/app_gate_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/text/typography.dart';

/// Mandatory store update. The router shows only this screen while the
/// store has a newer version (`appUpdateProvider`); there is no way to
/// dismiss it. Returning from the store re-runs the check.
class UpdateRequiredPage extends ConsumerWidget {
  const UpdateRequiredPage({super.key});

  Future<void> _openStore(BuildContext context) async {
    final store = Uri.parse(
      Platform.isIOS ? Endpoints.appStoreUrl : Endpoints.playStoreUrl,
    );
    final message = context.l10n.updateRequiredStoreError;
    var opened = false;
    try {
      opened = await launchUrl(store, mode: LaunchMode.externalApplication);
    } on Object {
      opened = false;
    }
    if (!opened && context.mounted) AppFeedback.toast(context, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decision = ref.watch(appUpdateProvider).value;
    final space = context.dimensions.space;
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(space.s24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.dimensions.breakpoint.mobile,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Assets.images.logo.image(
                      height: context.dimensions.layout.logoSmall,
                      fit: BoxFit.contain,
                    ),
                    Gap(space.s32),
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(space.s20),
                        decoration: BoxDecoration(
                          color: context.color.primary.tint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.system_update_rounded,
                          size: context.dimensions.size.iconDisplay,
                          color: context.color.primary.strong,
                        ),
                      ),
                    ),
                    Gap(space.s24),
                    HeadingLevel1Text(
                      l10n.updateRequiredTitle,
                      textAlign: TextAlign.center,
                    ),
                    Gap(space.s8),
                    BodySmallText.muted(
                      l10n.updateRequiredBody(
                        decision?.latestVersion ?? '',
                        decision?.currentVersion ?? '',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Gap(space.s32),
                    FilledButton.icon(
                      onPressed: () => _openStore(context),
                      icon: const Icon(Icons.download_rounded),
                      label: Text(l10n.homeUpdateNow),
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
