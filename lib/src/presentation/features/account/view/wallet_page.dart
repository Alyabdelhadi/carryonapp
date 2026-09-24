import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/base/result.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/extensions/localized_labels.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/failure_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/login_required_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/wallet_providers.dart';
import '../widgets/payout_request_sheet.dart';
import '../widgets/payout_request_tile.dart';
import '../widgets/wallet_balance_card.dart';
import '../widgets/wallet_transaction_tile.dart';

/// The carrier wallet: balance, payout requests and the ledger. Money only
/// arrives here from card-paid packages, so the page reads the rules it
/// shows from the backend.
class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.walTitle)),
      body: userId == null
          ? const LoginRequired(child: SizedBox.shrink())
          : _WalletBody(userId: userId),
    );
  }
}

class _WalletBody extends ConsumerWidget {
  const _WalletBody({required this.userId});

  final int userId;

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(walletOverviewProvider)
      ..invalidate(walletPayoutsProvider);
    try {
      await ref.read(walletOverviewProvider(userId).future);
    } on Object {
      // The body renders the failure.
    }
  }

  Future<void> _requestPayout(
    BuildContext context,
    WidgetRef ref,
    WalletOverview overview,
  ) async {
    final l10n = context.l10n;
    final draft = await showPayoutRequestSheet(context, overview: overview);
    if (draft == null || !context.mounted) return;
    final result = await ref
        .read(payoutActionsProvider.notifier)
        .request(userId: userId, draft: draft);
    if (!context.mounted) return;
    switch (result) {
      case Success():
        AppFeedback.toast(context, l10n.walPayoutRequestedToast);
      case Error(:final error):
        AppFeedback.error(context, error);
    }
  }

  Future<void> _cancelPayout(
    BuildContext context,
    WidgetRef ref,
    PayoutRequest payout,
  ) async {
    final l10n = context.l10n;
    final ok = await AppFeedback.confirm(
      context,
      title: l10n.areYouSure,
      message: l10n.walCancelConfirm,
      confirmLabel: l10n.yes,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final result = await ref
        .read(payoutActionsProvider.notifier)
        .cancel(userId: userId, payoutId: payout.id);
    if (!context.mounted) return;
    switch (result) {
      case Success():
        AppFeedback.toast(context, l10n.walPayoutCancelledToast);
      case Error(:final error):
        AppFeedback.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final space = context.dimensions.space;
    final overview = ref.watch(walletOverviewProvider(userId));
    final payouts = ref.watch(walletPayoutsProvider(userId));
    final busy = ref.watch(payoutActionsProvider).isLoading;

    return Stack(
      children: [
        switch (overview) {
          AsyncData(:final value) => RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                space.s16,
                space.s8,
                space.s16,
                space.s32,
              ),
              children: [
                WalletBalanceCard(
                  overview: value,
                  onRequestPayout: busy
                      ? null
                      : () => _requestPayout(context, ref, value),
                ),
                if (value.openPayout case final open?) ...[
                  Gap(space.s12),
                  _OpenPayoutCard(
                    payout: open,
                    rules: value.rules,
                    onCancel: busy
                        ? null
                        : () => _cancelPayout(context, ref, open),
                  ),
                ],
                if (payouts.value case final list? when list.isNotEmpty) ...[
                  Gap(space.s12),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeadingLevel3Text(l10n.walPayouts),
                        Gap(space.s4),
                        for (final p in list.take(10))
                          PayoutRequestTile(
                            payout: p,
                            rules: value.rules,
                            onCancel: p.isPending && !busy
                                ? () => _cancelPayout(context, ref, p)
                                : null,
                          ),
                      ],
                    ),
                  ),
                ],
                Gap(space.s12),
                if (value.transactions.isEmpty)
                  EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: l10n.walEmptyTitle,
                    message: l10n.walEmptyMessage,
                  )
                else
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeadingLevel3Text(l10n.walHistory),
                        Gap(space.s4),
                        for (final t in value.transactions)
                          WalletTransactionTile(transaction: t),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          AsyncError(:final error) => FailureView(
            error: error,
            onRetry: () => _refresh(ref),
          ),
          _ => const Center(child: LoadingIndicator()),
        },
        if (busy)
          ColoredBox(
            color: context.color.background.scrim,
            child: const Center(child: LoadingIndicator()),
          ),
      ],
    );
  }
}

/// The request waiting for the admin, with a cancel action.
class _OpenPayoutCard extends StatelessWidget {
  const _OpenPayoutCard({
    required this.payout,
    required this.rules,
    required this.onCancel,
  });

  final PayoutRequest payout;
  final PaymentRules rules;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      color: context.color.status.informationTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: context.dimensions.size.iconMedium,
                color: context.color.status.information,
              ),
              Gap(context.dimensions.space.s8),
              Expanded(child: HeadingLevel3Text(l10n.walOpenPayout)),
            ],
          ),
          Gap(context.dimensions.space.s8),
          BodySmallText(
            l10n.walOpenPayoutHint(
              Formatters.money(payout.amount, payout.currency),
              payoutMethodName(rules, payout.method),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onCancel,
              child: Text(l10n.walCancelPayout),
            ),
          ),
        ],
      ),
    );
  }
}
