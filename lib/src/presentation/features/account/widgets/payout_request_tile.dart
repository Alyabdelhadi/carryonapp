import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/extensions/localized_labels.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/text/typography.dart';

/// One payout request with its status; pending ones offer "Cancel".
class PayoutRequestTile extends StatelessWidget {
  const PayoutRequestTile({
    super.key,
    required this.payout,
    required this.rules,
    this.onCancel,
  });

  final PayoutRequest payout;
  final PaymentRules rules;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.color;
    final p = payout;
    final (fg, bg) = switch (p.status) {
      .pending => (c.status.information, c.status.informationTint),
      .paid => (c.status.success, c.status.successTint),
      .rejected => (c.status.danger, c.status.dangerTint),
      .cancelled || .unknown => (c.text.muted, c.border.subtle),
    };
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.space.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: BodySmallText(payoutMethodName(rules, p.method))),
              Text(
                Formatters.money(p.amount, p.currency),
                textDirection: TextDirection.ltr,
                style: context.textStyle.body.small.copyWith(
                  color: c.text.strong,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Gap(context.dimensions.space.s4),
          Wrap(
            spacing: context.dimensions.space.s8,
            runSpacing: context.dimensions.space.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TagChip(
                label: p.status.label(l10n),
                foreground: fg,
                background: bg,
              ),
              LabelText.muted(Formatters.monthDayYear(p.createdAt)),
              if ((p.reference ?? '').isNotEmpty)
                LabelText.muted(l10n.walReference(p.reference!)),
            ],
          ),
          if ((p.adminNote ?? '').isNotEmpty) ...[
            Gap(context.dimensions.space.s4),
            LabelText.muted(p.adminNote!),
          ],
          if (p.isPending && onCancel != null)
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
