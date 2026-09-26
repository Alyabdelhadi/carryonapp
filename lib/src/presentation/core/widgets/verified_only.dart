import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/localization.dart';
import '../../../domain/entities/identity_status.dart';
import '../../features/auth/riverpod/verify_identity_controller.dart';
import '../application_state/app_gate_provider/app_gate_provider.dart';
import 'empty_state.dart';
import 'feedback.dart';

/// Wraps the screens that send, receive or carry a package. While the
/// account is under review (Shufti has no verdict yet) it shows the
/// "Account under review" message instead, with a button to check again.
/// Accounts that were never verified never get here: the router keeps
/// them on the verification screen.
class VerifiedOnly extends ConsumerWidget {
  const VerifiedOnly({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isUnderReviewProvider)) return child;
    return Scaffold(appBar: AppBar(), body: const UnderReviewView());
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
