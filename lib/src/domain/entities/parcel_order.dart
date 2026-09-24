import 'catalog.dart';

/// Lifecycle of a parcel order, mirroring the backend's `status` column.
enum ParcelOrderStatus {
  unassigned('Unassigned'),
  assigned('Assigned'),
  picked('Picked'),
  transit('Transit'),
  delivered('Delivered'),
  cancelled('Cancelled'),
  expired('Expired'),
  unknown('');

  const ParcelOrderStatus(this.wire);

  /// The exact string the backend stores.
  final String wire;

  static ParcelOrderStatus fromWire(String? value) {
    final needle = (value ?? '').trim().toLowerCase();
    for (final status in values) {
      if (status.wire.toLowerCase() == needle) return status;
    }
    return unknown;
  }

  bool get isActive => this == assigned || this == picked || this == transit;

  bool get isFinal => this == delivered || this == cancelled || this == expired;
}

/// Sender (`s_*`) or receiver (`r_*`) location on a parcel order, and the
/// same shape the order form submits.
class OrderAddress {
  const OrderAddress({
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
    this.city,
    this.street = '',
    this.building = '',
    this.apartment = '',
    this.notes,
    this.save = false,
    this.cityAr,
    this.countryAr,
  });

  /// Display label / short address name.
  final String name;
  final String? city;
  final String country;

  /// Arabic forms resolved by the backend from its places tables; null
  /// when unknown. Never sent back to the server.
  final String? cityAr;
  final String? countryAr;

  String? cityFor(String languageCode) =>
      PlaceNames.pickNullable(languageCode, city, cityAr);

  String countryFor(String languageCode) =>
      PlaceNames.pick(languageCode, country, countryAr);
  final double lat;
  final double lng;
  final String street;
  final String building;
  final String apartment;
  final String? notes;

  /// Ask the backend to also store this as a saved address.
  final bool save;

  String get summary => summaryFor('en');

  /// [summary] with the city and country in the given language.
  String summaryFor(String languageCode) {
    final parts = [
      name,
      street,
      building,
      apartment,
      cityFor(languageCode),
      countryFor(languageCode),
    ].where((p) => p != null && p.trim().isNotEmpty).cast<String>().toList();
    return parts.join(', ');
  }

  OrderAddress copyWith({
    String? name,
    String? city,
    String? country,
    double? lat,
    double? lng,
    String? street,
    String? building,
    String? apartment,
    String? notes,
    bool? save,
  }) {
    return OrderAddress(
      name: name ?? this.name,
      city: city ?? this.city,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      street: street ?? this.street,
      building: building ?? this.building,
      apartment: apartment ?? this.apartment,
      notes: notes ?? this.notes,
      save: save ?? this.save,
    );
  }
}

/// A parcel order as returned by the list and action endpoints. The joined
/// columns (`cate_*`, `carrier_*`, `client_*`, `is_read`) are present only
/// on the list endpoints that select them; they are null otherwise.
class ParcelOrder {
  const ParcelOrder({
    required this.id,
    required this.userId,
    required this.status,
    required this.sender,
    required this.receiver,
    this.carrierId,
    this.categoryId,
    this.categoryName,
    this.categoryNameAr,
    this.categoryImage,
    this.senderName = '',
    this.senderPhone = '',
    this.receiverName = '',
    this.receiverPhone = '',
    this.type,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentAmount,
    this.paymentCurrency,
    this.notes,
    this.value,
    this.weight,
    this.amount,
    this.description,
    this.orderDate,
    this.createdAt,
    this.updatedAt,
    this.distanceKm,
    this.co2SavedPercent,
    this.treesSaved,
    this.carrierName,
    this.carrierSelfie,
    this.carrierPhone,
    this.carrierAverageRating,
    this.carrierRatingsCount,
    this.clientName,
    this.clientPhone,
    this.isRead,
  });

  final int id;
  final int userId;
  final int? carrierId;
  final ParcelOrderStatus status;
  final int? categoryId;
  final String? categoryName;

  /// Arabic category name from the backend; null when not provided.
  final String? categoryNameAr;

  String? categoryNameFor(String languageCode) =>
      PlaceNames.pickNullable(languageCode, categoryName, categoryNameAr);

  /// File name under `upload/categories/`.
  final String? categoryImage;

  final OrderAddress sender;
  final OrderAddress receiver;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;

  /// 1 = send flow, 2 = receive flow (as recorded by the order form).
  final int? type;
  final String? paymentMethod;
  final String? paymentStatus;
  final double? paymentAmount;
  final String? paymentCurrency;
  final String? notes;

  /// Declared item value, free text (e.g. "220").
  final String? value;

  /// Weight bucket, free text (e.g. "under 1kg").
  final String? weight;

  /// Reward offered to the carrier, free text ("20", "Free").
  final String? amount;
  final String? description;

  /// "Needed before" date; null means flexible / needed soon.
  final DateTime? orderDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? distanceKm;
  final double? co2SavedPercent;
  final double? treesSaved;

  // Joined on `myCreatedParcelOrders`.
  final String? carrierName;
  final String? carrierSelfie;
  final String? carrierPhone;
  final double? carrierAverageRating;
  final int? carrierRatingsCount;

  // Joined on `myCarriedParcelOrders`.
  final String? clientName;
  final String? clientPhone;

  // Joined on the carrier matching list.
  final bool? isRead;

  bool get isFreeReward =>
      amount == null || amount!.trim().toLowerCase() == 'free';

  bool get hasNeededBeforeDate => orderDate != null;

  bool isCreatedBy(int? id) => id != null && userId == id;

  bool isCarriedBy(int? id) => id != null && carrierId == id;
}
