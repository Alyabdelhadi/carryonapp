import 'parcel_order.dart';

/// Which side of the exchange the current user is on when creating an
/// order. The Ionic app had two near-identical forms (`pview` for
/// receiving, `pview1` for sending); the draft keeps one shape and records
/// the flow in [type] (1 = send, 2 = receive), as the backend expects.
enum ParcelFlow {
  send(1),
  receive(2);

  const ParcelFlow(this.type);

  final int type;
}

/// Everything the order form collects, and the body sent to
/// `createParcelOrder` / `updateParcelOrder`.
class ParcelOrderDraft {
  const ParcelOrderDraft({
    required this.userId,
    required this.flow,
    required this.categoryId,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.sender,
    required this.receiver,
    required this.weight,
    required this.reward,
    this.orderId,
    this.paymentMethodId = 1,
    this.value,
    this.description,
    this.notes,
    this.neededBefore,
    this.distanceKm,
  });

  /// Set when editing an existing order.
  final int? orderId;
  final int userId;
  final ParcelFlow flow;
  final int categoryId;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final OrderAddress sender;
  final OrderAddress receiver;

  /// Weight bucket label, e.g. "under 1kg".
  final String weight;

  /// Reward for the carrier, free text: "20", "Free".
  final String reward;
  final int paymentMethodId;

  /// Declared package value.
  final String? value;
  final String? description;
  final String? notes;

  /// Null means "Needed Soon" (flexible).
  final DateTime? neededBefore;
  final double? distanceKm;

  bool get isEdit => orderId != null;

  ParcelOrderDraft copyWith({
    int? orderId,
    int? userId,
    ParcelFlow? flow,
    int? categoryId,
    String? senderName,
    String? senderPhone,
    String? receiverName,
    String? receiverPhone,
    OrderAddress? sender,
    OrderAddress? receiver,
    String? weight,
    String? reward,
    int? paymentMethodId,
    String? value,
    String? description,
    String? notes,
    DateTime? neededBefore,
    bool clearNeededBefore = false,
    double? distanceKm,
  }) {
    return ParcelOrderDraft(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      flow: flow ?? this.flow,
      categoryId: categoryId ?? this.categoryId,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      weight: weight ?? this.weight,
      reward: reward ?? this.reward,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      value: value ?? this.value,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      neededBefore: clearNeededBefore
          ? null
          : neededBefore ?? this.neededBefore,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
