import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/extensions/localized_labels.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/text/typography.dart';

/// One ledger row: type icon, label and reference, signed amount, date.
class WalletTransactionTile extends StatelessWidget {
  const WalletTransactionTile({super.key, required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = transaction;
    final positive = t.amount >= 0;
    final c = context.color;
    final (icon, tint) = switch (t.type) {
      .earning => (Icons.add_circle_outline_rounded, c.status.success),
      .payout => (Icons.outbox_outlined, c.status.information),
      .payoutReversal => (Icons.undo_rounded, c.status.information),
      .refund => (Icons.replay_rounded, c.status.danger),
      .adjustment => (Icons.tune_rounded, c.text.muted),
      .unknown => (Icons.swap_vert_rounded, c.text.muted),
    };
    final subtitle = [
      if (t.orderId != null) l10n.walPackageRef('${t.orderId}'),
      if (t.orderId == null && (t.note ?? '').isNotEmpty) t.note!,
      if (t.isOnHold) l10n.walHoldUntil(Formatters.monthDayYear(t.availableAt)),
    ].join(' · ');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.space.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.dimensions.size.touch,
            height: context.dimensions.size.touch,
            decoration: BoxDecoration(
              color: c.border.subtle,
              borderRadius: BorderRadius.circular(
                context.dimensions.radius.medium,
              ),
            ),
            child: Icon(
              icon,
              color: tint,
              size: context.dimensions.size.iconLarge,
            ),
          ),
          Gap(context.dimensions.space.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BodySmallText(t.type.label(l10n)),
                if (subtitle.isNotEmpty) LabelText.muted(subtitle),
                LabelText.muted(Formatters.monthDayYear(t.createdAt)),
              ],
            ),
          ),
          Gap(context.dimensions.space.s8),
          Text(
            '${positive ? '+' : '-'}'
            '${Formatters.money(t.amount.abs(), t.currency)}',
            textDirection: TextDirection.ltr,
            style: context.textStyle.body.small.copyWith(
              color: positive ? c.status.success : c.text.strong,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
