import '../../../core/gen/l10n/app_localizations.dart';
import '../../../domain/entities/entities.dart';

/// Localized display names for domain enums, which carry wire values only.
extension ParcelOrderStatusLabel on ParcelOrderStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ParcelOrderStatus.unassigned => l10n.statusUnassigned,
    ParcelOrderStatus.assigned => l10n.statusAssigned,
    ParcelOrderStatus.picked => l10n.statusPicked,
    ParcelOrderStatus.transit => l10n.statusTransit,
    ParcelOrderStatus.delivered => l10n.statusDelivered,
    ParcelOrderStatus.cancelled => l10n.statusCancelled,
    ParcelOrderStatus.expired => l10n.statusExpired,
    ParcelOrderStatus.unknown => l10n.statusUnknown,
  };
}

extension TripFrequencyLabel on TripFrequency {
  String label(AppLocalizations l10n) => switch (this) {
    TripFrequency.oneTime => l10n.tripFrequencyOneTime,
    TripFrequency.daily => l10n.tripFrequencyDaily,
    TripFrequency.weekdays => l10n.tripFrequencyWeekdays,
    TripFrequency.weekends => l10n.tripFrequencyWeekends,
  };
}

extension OrderPaymentStatusLabel on OrderPaymentStatus {
  String label(AppLocalizations l10n) => switch (this) {
    OrderPaymentStatus.unpaid => l10n.payStatusUnpaid,
    OrderPaymentStatus.processing => l10n.payStatusProcessing,
    OrderPaymentStatus.paid => l10n.payStatusPaid,
    OrderPaymentStatus.failed => l10n.payStatusFailed,
    OrderPaymentStatus.refunded => l10n.payStatusRefunded,
    OrderPaymentStatus.refundPending => l10n.payStatusRefundPending,
    OrderPaymentStatus.cash => l10n.payStatusCash,
  };
}

extension WalletTransactionTypeLabel on WalletTransactionType {
  String label(AppLocalizations l10n) => switch (this) {
    WalletTransactionType.earning => l10n.walTypeEarning,
    WalletTransactionType.payout => l10n.walTypePayout,
    WalletTransactionType.payoutReversal => l10n.walTypePayoutReversal,
    WalletTransactionType.refund => l10n.walTypeRefund,
    WalletTransactionType.adjustment => l10n.walTypeAdjustment,
    WalletTransactionType.unknown => l10n.walTypeUnknown,
  };
}

extension PayoutStatusLabel on PayoutStatus {
  String label(AppLocalizations l10n) => switch (this) {
    PayoutStatus.pending => l10n.walStatusPending,
    PayoutStatus.paid => l10n.walStatusPaid,
    PayoutStatus.rejected => l10n.walStatusRejected,
    PayoutStatus.cancelled => l10n.walStatusCancelled,
    PayoutStatus.unknown => l10n.walStatusUnknown,
  };
}

/// The admin's label for a payout method code, or the code humanised.
String payoutMethodName(PaymentRules rules, String code) {
  for (final m in rules.payoutMethods) {
    if (m.code == code) return m.name;
  }
  return code.replaceAll('_', ' ');
}
