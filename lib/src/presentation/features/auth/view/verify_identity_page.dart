import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../domain/failures/business_failure.dart';
import '../../../core/application_state/app_settings_provider/app_settings_provider.dart';
import '../../../core/application_state/logout_provider/logout_provider.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../model/document_normalizer.dart';
import '../riverpod/verify_identity_controller.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/document_upload_tile.dart';

/// The only screen a signed-in account sees until its identity is
/// verified, while the admin has the Shufti check on (router gate
/// `Routes.verifyIdentity`). Old accounts land here after updating the
/// app; so do accounts whose last check was rejected. Logging out is the
/// only other way out.
///
/// In live mode (`AppSettings.shuftiLive`) there are no uploads: the page
/// opens Shufti's own page in an in-app browser (live selfie with liveness
/// check + ID scan) and asks the backend for the result when the user
/// comes back (on resume, or with the "check result" button, since an iOS
/// Safari sheet does not pause the app).
class VerifyIdentityPage extends ConsumerStatefulWidget {
  const VerifyIdentityPage({super.key});

  @override
  ConsumerState<VerifyIdentityPage> createState() => _VerifyIdentityPageState();
}

class _VerifyIdentityPageState extends ConsumerState<VerifyIdentityPage> {
  PickedDocument? _selfie;
  PickedDocument? _identity;

  /// A live session was opened and its result is not known yet.
  bool _awaitingLive = false;
  bool _checkingLive = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // an Android Custom Tab pauses the app: check when the user is back
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_awaitingLive) _checkLive();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _startLive() async {
    final l10n = context.l10n;
    final url = await ref
        .read(verifyIdentityControllerProvider.notifier)
        .startLive(Localizations.localeOf(context).languageCode);
    if (url == null || !mounted) return;
    setState(() => _awaitingLive = true);
    final opened = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    if (!opened && mounted) {
      setState(() => _awaitingLive = false);
      AppFeedback.toast(context, l10n.idvLiveOpenFailed);
    }
  }

  Future<void> _checkLive() async {
    if (_checkingLive) return;
    final l10n = context.l10n;
    setState(() => _checkingLive = true);
    final status = await refreshIdentityStatus(ref);
    if (!mounted) return;
    ref.invalidate(currentUserProvider);
    setState(() {
      _checkingLive = false;
      // not submitted yet (or no answer): keep offering the check
      _awaitingLive = status == null || status == IdentityStatus.none;
    });
    final message = switch (status) {
      IdentityStatus.verified => l10n.idvVerifiedToast,
      IdentityStatus.pending => l10n.idvUnderReviewSnack,
      IdentityStatus.declined || IdentityStatus.invalid => null,
      IdentityStatus.none || null => l10n.idvLiveNotFinished,
    };
    if (message != null) AppFeedback.toast(context, message);
  }

  Future<void> _submit() async {
    final selfie = _selfie;
    final identity = _identity;
    if (selfie == null || identity == null) {
      AppFeedback.toast(context, context.l10n.authUploadBothDocuments);
      return;
    }
    final l10n = context.l10n;
    final user = await ref
        .read(verifyIdentityControllerProvider.notifier)
        .submit(selfiePath: selfie.path, identityPath: identity.path);
    if (user == null || !mounted) return;
    ref.invalidate(currentUserProvider);
    AppFeedback.toast(
      context,
      user.isVerified ? l10n.idvVerifiedToast : l10n.idvUnderReviewSnack,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(verifyIdentityControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        AppFeedback.error(context, error);
        // the admin switched verification modes since the settings loaded
        if (error case BusinessFailure(
          cause: IdentityVerificationFailure(
            kind: IdentityVerificationFailureKind.liveRequired,
          ),
        )) {
          ref.invalidate(appSettingsProvider);
        }
      }
    });
    final starting = ref.watch(verifyIdentityControllerProvider).isLoading;
    final live = ref.watch(appSettingsProvider).value?.shuftiLive ?? false;
    final busy = starting || _checkingLive;
    final loggingOut = ref.watch(logoutProvider).isLoading;
    final status = ref.watch(currentUserProvider)?.identityStatus;
    final space = context.dimensions.space;
    final l10n = context.l10n;
    final enabled = !busy && !loggingOut;
    final declined =
        status == IdentityStatus.declined || status == IdentityStatus.invalid;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            AuthPageLayout(
              title: l10n.idvTitle,
              subtitle: live ? l10n.idvLiveSubtitle : l10n.idvSubtitle,
              form: live
                  ? _LiveForm(
                      declined: declined,
                      awaitingResult: _awaitingLive,
                      enabled: enabled,
                      onStart: _startLive,
                      onCheck: _checkLive,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (declined) ...[
                          _Note(
                            icon: Icons.error_outline_rounded,
                            color: context.color.status.danger,
                            text: l10n.idvDeclinedNote,
                          ),
                          Gap(space.s16),
                        ],
                        DocumentUploadTile(
                          icon: Icons.face_rounded,
                          title: l10n.authSelfieTitle,
                          subtitle: l10n.authSelfieSubtitle,
                          file: _selfie,
                          onChanged: (f) => setState(() => _selfie = f),
                          preferFrontCamera: true,
                          enabled: enabled,
                        ),
                        Gap(space.s12),
                        DocumentUploadTile(
                          icon: Icons.badge_outlined,
                          title: l10n.authIdentityTitle,
                          subtitle: l10n.authIdentitySubtitle,
                          file: _identity,
                          onChanged: (f) => setState(() => _identity = f),
                          allowPdf: true,
                          enabled: enabled,
                        ),
                        Gap(space.s16),
                        _Note(
                          icon: Icons.shield_outlined,
                          color: context.color.status.success,
                          text: l10n.idvPrivacyNote,
                        ),
                        Gap(space.s20),
                        FilledButton.icon(
                          onPressed:
                              enabled && _selfie != null && _identity != null
                              ? _submit
                              : null,
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.verified_user_outlined),
                          label: Text(l10n.idvSubmit),
                        ),
                      ],
                    ),
              footer: TextButton.icon(
                onPressed: enabled
                    ? () => ref.read(logoutProvider.notifier).call()
                    : null,
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.logout),
              ),
            ),
            if (busy)
              Positioned.fill(
                child: _VerifyingOverlay(
                  text: !live
                      ? l10n.idvVerifying
                      : _checkingLive
                      ? l10n.idvLiveChecking
                      : l10n.idvLiveOpening,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Live mode: what will happen, then "Start verification"; once a session
/// was opened, "I've finished" asks the backend for the result.
class _LiveForm extends StatelessWidget {
  const _LiveForm({
    required this.declined,
    required this.awaitingResult,
    required this.enabled,
    required this.onStart,
    required this.onCheck,
  });

  final bool declined;
  final bool awaitingResult;
  final bool enabled;
  final VoidCallback onStart;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (declined) ...[
          _Note(
            icon: Icons.error_outline_rounded,
            color: context.color.status.danger,
            text: l10n.idvLiveDeclinedNote,
          ),
          Gap(space.s16),
        ],
        SectionCard(
          padding: EdgeInsets.all(space.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Note(
                icon: Icons.face_retouching_natural_rounded,
                color: context.color.status.success,
                text: l10n.idvLiveStepSelfie,
              ),
              Gap(space.s12),
              _Note(
                icon: Icons.badge_outlined,
                color: context.color.status.success,
                text: l10n.idvLiveStepDocument,
              ),
              Gap(space.s12),
              _Note(
                icon: Icons.wb_sunny_outlined,
                color: context.color.status.success,
                text: l10n.idvLiveStepLight,
              ),
            ],
          ),
        ),
        Gap(space.s16),
        _Note(
          icon: Icons.shield_outlined,
          color: context.color.status.success,
          text: l10n.idvPrivacyNote,
        ),
        Gap(space.s20),
        if (awaitingResult) ...[
          FilledButton.icon(
            onPressed: enabled ? onCheck : null,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.task_alt_rounded),
            label: Text(l10n.idvLiveCheck),
          ),
          Gap(space.s8),
          OutlinedButton(
            onPressed: enabled ? onStart : null,
            child: Text(l10n.idvLiveRestart),
          ),
        ] else
          FilledButton.icon(
            onPressed: enabled ? onStart : null,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(l10n.idvLiveStart),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: context.dimensions.size.iconLarge, color: color),
        Gap(context.dimensions.space.s8),
        Expanded(child: BodySmallText.muted(text)),
      ],
    );
  }
}

class _VerifyingOverlay extends StatelessWidget {
  const _VerifyingOverlay({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    return ColoredBox(
      color: context.color.background.scrim,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(space.s24),
          child: SectionCard(
            padding: EdgeInsets.all(space.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                Gap(space.s20),
                LabelText(text, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
