import 'catalog.dart';

/// Balance figures of the carrier wallet (`/wallet`).
class WalletSummary {
  const WalletSummary({
    this.balance = 0,
    this.available = 0,
    this.pending = 0,
    this.currency = 'USD',
  });

  final double balance;

  /// Withdrawable now: balance minus earnings still on hold.
  final double available;

  /// Earnings inside the payout hold window.
  final double pending;
  final String currency;
}

enum WalletTransactionType {
  earning('earning'),
  payout('payout'),
  payoutReversal('payout_reversal'),
  refund('refund'),
  adjustment('adjustment'),
  unknown('');

  const WalletTransactionType(this.wire);

  final String wire;

  static WalletTransactionType fromWire(String? value) {
    final needle = (value ?? '').trim().toLowerCase();
    for (final type in values) {
      if (type.wire == needle) return type;
    }
    return unknown;
  }
}

/// One ledger row.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.balanceAfter,
    this.orderId,
    this.payoutRequestId,
    this.availableAt,
    this.note,
    this.createdAt,
  });

  final int id;
  final WalletTransactionType type;

  /// Signed: earnings positive, payouts negative.
  final double amount;
  final String currency;
  final double balanceAfter;
  final int? orderId;
  final int? payoutRequestId;

  /// Earnings become withdrawable after this.
  final DateTime? availableAt;
  final String? note;
  final DateTime? createdAt;

  bool get isOnHold =>
      type == WalletTransactionType.earning &&
      availableAt != null &&
      availableAt!.isAfter(DateTime.now());
}

enum PayoutStatus {
  pending('pending'),
  paid('paid'),
  rejected('rejected'),
  cancelled('cancelled'),
  unknown('');

  const PayoutStatus(this.wire);

  final String wire;

  static PayoutStatus fromWire(String? value) {
    final needle = (value ?? '').trim().toLowerCase();
    for (final status in values) {
      if (status.wire == needle) return status;
    }
    return unknown;
  }
}

/// A withdrawal the carrier asked for; the admin pays it by hand.
class PayoutRequest {
  const PayoutRequest({
    required this.id,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    this.details = const {},
    this.reference,
    this.adminNote,
    this.processedAt,
    this.createdAt,
  });

  final int id;
  final double amount;
  final String currency;

  /// Payout method code (`omt`, `bank_transfer`, ...).
  final String method;
  final PayoutStatus status;

  /// Where to send the money (IBAN, phone, email...).
  final Map<String, String> details;
  final String? reference;
  final String? adminNote;
  final DateTime? processedAt;
  final DateTime? createdAt;

  bool get isPending => status == PayoutStatus.pending;
}

/// Everything the Wallet page shows in one call.
class WalletOverview {
  const WalletOverview({
    required this.summary,
    required this.rules,
    this.transactions = const [],
    this.openPayout,
  });

  final WalletSummary summary;
  final PaymentRules rules;
  final List<WalletTransaction> transactions;

  /// The request waiting for the admin, if any.
  final PayoutRequest? openPayout;

  bool get hasActivity => transactions.isNotEmpty || summary.balance != 0;

  /// Enough available money and no request already pending.
  bool get canRequestPayout =>
      openPayout == null && summary.available >= rules.payoutMinimum;
}

/// What the carrier fills in to withdraw.
class PayoutDraft {
  const PayoutDraft({
    required this.amount,
    required this.method,
    required this.details,
  });

  final double amount;
  final String method;
  final Map<String, String> details;
}
