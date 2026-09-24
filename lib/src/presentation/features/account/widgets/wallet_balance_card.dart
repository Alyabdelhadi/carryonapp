import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';

/// The headline of the Wallet page: balance, what can be withdrawn, what
/// is still on hold, and the "Request payout" button.
class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    super.key,
    required this.overview,
    required this.onRequestPayout,
  });

  final WalletOverview overview;
  final VoidCallback? onRequestPayout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = overview.summary;
    final rules = overview.rules;
    final space = context.dimensions.space;
    return SectionCard(
      color: context.color.primary.tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: context.dimensions.size.iconMedium,
                color: context.color.primary.strong,
              ),
              Gap(space.s8),
              BodySmallText.muted(l10n.walBalance),
            ],
          ),
          Gap(space.s8),
          Text(
            Formatters.money(s.balance, s.currency),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            style: context.textStyle.heading.level1.copyWith(
              color: context.color.text.strong,
            ),
          ),
          Gap(space.s12),
          _Line(
            label: l10n.walAvailable,
            value: Formatters.money(s.available, s.currency),
            strong: true,
          ),
          if (s.pending > 0)
            _Line(
              label: l10n.walOnHold,
              value: Formatters.money(s.pending, s.currency),
            ),
          Gap(space.s12),
          LabelText.muted(l10n.walHoldHint(rules.payoutHoldDays)),
          Gap(space.s4),
          LabelText.muted(
            l10n.walMinimumHint(
              Formatters.money(rules.payoutMinimum, s.currency),
            ),
          ),
          Gap(space.s16),
          FilledButton.icon(
            onPressed: overview.canRequestPayout ? onRequestPayout : null,
            icon: const Icon(Icons.outbox_outlined),
            label: Text(l10n.walRequestPayout),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.space.s2),
      child: Row(
        children: [
          Expanded(child: BodySmallText.muted(label)),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: context.textStyle.body.small.copyWith(
              color: context.color.text.strong,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
