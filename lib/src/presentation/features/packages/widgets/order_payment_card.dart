import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/app_settings_provider/app_settings_provider.dart';
import '../../../core/extensions/localized_labels.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import 'order_overview_card.dart';
import 'payment_status_badge.dart';

/// "Payment" on the order detail: method, status, amount, and what the
/// current viewer needs to know next (pay before a deadline, wait for the
/// sender, what the carrier earns). Cash orders get a one-line card.
class OrderPaymentCard extends ConsumerWidget {
  const OrderPaymentCard({
    super.key,
    required this.order,
    required this.isCreator,
    required this.isCarrier,
    this.onPayNow,
  });

  final ParcelOrder order;
  final bool isCreator;
  final bool isCarrier;
  final VoidCallback? onPayNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rules = ref.watch(paymentRulesProvider);
    final status = order.payment;
    final colors = paymentStatusColors(context, status);
    final gap = Gap(context.dimensions.space.s8);

    final notice = switch (status) {
      _ when isCreator && order.canPayNow => l10n.payCreatorHint,
      _ when isCarrier && order.awaitingPayment => l10n.payWaitingForSender,
      .failed when isCreator => l10n.payFailedNotice,
      .refunded when isCreator => l10n.payRefundedNotice,
      _ => null,
    };

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                order.isOnlinePayment
                    ? Icons.credit_card_rounded
                    : Icons.payments_outlined,
                size: context.dimensions.size.iconMedium,
                color: context.color.primary.strong,
              ),
              Gap(context.dimensions.space.s8),
              Expanded(child: HeadingLevel3Text(l10n.payTitle)),
              PaymentStatusBadge(
                order: order,
                viewerIsCreator: isCreator,
                showCash: true,
              ),
            ],
          ),
          gap,
          OrderDetailLine(
            label: l10n.payMethodLabel,
            value: order.isOnlinePayment ? l10n.payCard : l10n.payStatusCash,
          ),
          if (order.isOnlinePayment) ...[
            OrderDetailLine(
              label: l10n.payStatusLabel,
              value: status.label(l10n),
            ),
            if ((order.paymentAmount ?? 0) > 0)
              OrderDetailLine(
                label: l10n.payAmountLabel,
                value: Formatters.money(
                  order.paymentAmount,
                  order.paymentCurrency,
                ),
              ),
            if (isCreator &&
                order.awaitingPayment &&
                order.paymentDeadlineAt != null)
              OrderDetailLine(
                label: l10n.payDeadlineLabel,
                value: Formatters.weekdayMonthDay(order.paymentDeadlineAt),
              ),
            if (isCarrier && order.carrierEarning != null) ...[
              gap,
              _EarningLine(
                amount: Formatters.money(
                  order.carrierEarning,
                  order.paymentCurrency,
                ),
                percent: Formatters.percent(rules.commissionPercent),
                color: colors.foreground,
              ),
            ],
          ],
          if (notice != null) ...[
            gap,
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(
                  context.dimensions.radius.medium,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(context.dimensions.space.s12),
                child: BodySmallText(notice),
              ),
            ),
          ],
          if (isCreator && order.canPayNow && onPayNow != null) ...[
            Gap(context.dimensions.space.s12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPayNow,
                icon: const Icon(Icons.lock_outline_rounded),
                label: Text(l10n.payNow),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EarningLine extends StatelessWidget {
  const _EarningLine({
    required this.amount,
    required this.percent,
    required this.color,
  });

  final String amount;
  final String percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.account_balance_wallet_outlined,
          size: context.dimensions.size.iconSmall,
          color: color,
        ),
        Gap(context.dimensions.space.s8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: context.textStyle.body.small.copyWith(
                color: context.color.text.strong,
              ),
              children: [
                TextSpan(
                  text: l10n.payYouEarn(amount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: l10n.payAfterFee(percent),
                  style: TextStyle(color: context.color.text.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
