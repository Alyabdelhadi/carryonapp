import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/localization.dart';
import '../../../domain/entities/identity_status.dart';
import '../../features/auth/riverpod/verify_identity_controller.dart';
import '../application_state/app_gate_provider/app_gate_provider.dart';
import '../application_state/app_settings_provider/app_settings_provider.dart';
import '../router/routes.dart';
import 'empty_state.dart';
import 'feedback.dart';

/// Wraps the screens that send, receive or carry a package (and add a
/// trip). An account that is not verified yet sees "Verify your identity"
/// with a button to the verification screen; one under review (Shufti or
/// the admin has not decided yet) sees "Account under review" with a
/// button to check again. The backend refuses those actions too.
class VerifiedOnly extends ConsumerWidget {
  const VerifiedOnly({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(identityGateProvider);
    final Widget body;
    switch (gate.value) {
      case IdentityGate.required:
        body = const VerifyRequiredView();
      case IdentityGate.underReview:
        body = const UnderReviewView();
      case null when gate.isLoading:
        body = const Center(child: CircularProgressIndicator());
      default:
        return child;
    }
    return Scaffold(appBar: AppBar(), body: body);
  }
}

/// For actions outside a [VerifiedOnly] screen (e.g. "Carry this package"
/// on an order): true when the account may go ahead; otherwise explains
/// why not, opening the verification screen when that is the next step.
bool ensureIdentityVerified(BuildContext context, WidgetRef ref) {
  switch (ref.read(identityGateProvider).value) {
    case IdentityGate.required:
      context.pushNamed(Routes.verifyIdentity.name);
      return false;
    case IdentityGate.underReview:
      AppFeedback.toast(context, context.l10n.idvUnderReviewSnack);
      return false;
    default:
      return true;
  }
}

/// "Verify your identity" with the button to the verification screen.
class VerifyRequiredView extends ConsumerWidget {
  const VerifyRequiredView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final live = ref.watch(appSettingsProvider).value?.shuftiLive ?? false;
    return EmptyState(
      icon: Icons.verified_user_outlined,
      title: l10n.idvTitle,
      message: live ? l10n.idvRequiredBodyLive : l10n.idvRequiredBodyManual,
      actionLabel: l10n.idvSubmit,
      onAction: () => context.pushNamed(Routes.verifyIdentity.name),
    );
  }
}

/// The "Account under review" message with its "Check again" action.
class UnderReviewView extends ConsumerStatefulWidget {
  const UnderReviewView({super.key});

  @override
  ConsumerState<UnderReviewView> createState() => _UnderReviewViewState();
}

class _UnderReviewViewState extends ConsumerState<UnderReviewView> {
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    final l10n = context.l10n;
    final status = await refreshIdentityStatus(ref);
    if (!mounted) return;
    setState(() => _checking = false);
    if (status == null || status == IdentityStatus.pending) {
      AppFeedback.toast(context, l10n.idvStillUnderReview);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      icon: Icons.hourglass_top_rounded,
      title: l10n.idvUnderReviewTitle,
      message: l10n.idvUnderReviewBody,
      actionLabel: l10n.idvCheckStatus,
      onAction: _checking ? null : _check,
    );
  }
}
