import 'package:flutter/material.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/extensions/localized_labels.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/status_badge.dart';

/// The colour pair a payment status renders in.
({Color foreground, Color background}) paymentStatusColors(
  BuildContext context,
  OrderPaymentStatus status,
) {
  final c = context.color;
  return switch (status) {
    .paid => (foreground: c.status.success, background: c.status.successTint),
    .unpaid || .processing => (
      foreground: c.status.information,
      background: c.status.informationTint,
    ),
    .failed || .refundPending => (
      foreground: c.status.danger,
      background: c.status.dangerTint,
    ),
    .refunded ||
    .cash => (foreground: c.text.muted, background: c.border.subtle),
  };
}

/// A small pill with the order's payment state. Renders nothing for cash
/// orders unless [showCash] is set.
class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({
    super.key,
    required this.order,
    this.viewerIsCreator = false,
    this.showCash = false,
  });

  final ParcelOrder order;

  /// The creator of an unpaid, accepted order sees "Pay now" instead of
  /// "Not paid yet".
  final bool viewerIsCreator;
  final bool showCash;

  @override
  Widget build(BuildContext context) {
    if (!order.isOnlinePayment && !showCash) return const SizedBox.shrink();
    final l10n = context.l10n;
    final status = order.payment;
    final colors = paymentStatusColors(context, status);
    final (label, icon) = switch (status) {
      .unpaid || .failed when order.canPayNow && viewerIsCreator => (
        l10n.payNow,
        Icons.credit_card_rounded,
      ),
      .unpaid || .processing || .failed when order.awaitingPayment => (
        l10n.payAwaiting,
        Icons.hourglass_top_rounded,
      ),
      .paid => (l10n.payStatusPaid, Icons.check_circle_outline_rounded),
      _ => (status.label(l10n), null),
    };
    return TagChip(
      label: label,
      icon: icon,
      foreground: colors.foreground,
      background: colors.background,
    );
  }
}
