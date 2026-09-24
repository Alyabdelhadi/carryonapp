import '../../domain/entities/entities.dart';
import '../services/network/exceptions.dart';

/// Lenient JSON decoding for the CarryOn backend, which mixes ints and
/// strings freely (`"1"` vs `1`, lat/lng as strings, decimals as strings).
/// Every reader here tolerates that instead of throwing on a type mismatch.
abstract final class Json {
  static Map<String, dynamic> asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const ApiResponseException('Unexpected response shape');
  }

  static List<Map<String, dynamic>> asList(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (value is Map && value['data'] is List) return asList(value['data']);
    return const [];
  }

  static int? toInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is bool) return v ? 1 : 0;
    return int.tryParse(v.toString().trim()) ??
        double.tryParse(v.toString().trim())?.toInt();
  }

  static double? toDouble(Object? v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().trim().replaceAll(',', '.'));
  }

  static String? toStr(Object? v) {
    if (v == null) return null;
    final s = v.toString();
    if (s == 'null') return null;
    return s;
  }

  static String str(Object? v, [String fallback = '']) => toStr(v) ?? fallback;

  static bool toBool(Object? v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase().trim();
    return s == '1' || s == 'true' || s == 'yes';
  }

  static DateTime? toDate(Object? v) {
    final s = toStr(v);
    if (s == null || s.trim().isEmpty) return null;
    return DateTime.tryParse(s.trim().replaceFirst(' ', 'T'));
  }

  static String? dateOnly(DateTime? d) {
    if (d == null) return null;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// The backend signals success as `{"msg":"done"}` or
  /// `{"message":"done"}` with HTTP 200, and failure as any other string in
  /// those keys (plus an optional `error`). Throws [ApiResponseException]
  /// carrying the server's text on failure.
  static Map<String, dynamic> requireDone(Object? body) {
    final map = asMap(body);
    final msg = toStr(map['msg']) ?? toStr(map['message']);
    if (msg != null && msg.toLowerCase() == 'done') return map;
    final error = toStr(map['error']) ?? msg ?? 'Request failed';
    throw ApiResponseException(error);
  }
}

abstract final class AppUserMapper {
  static AppUser fromJson(Map<String, dynamic> j) {
    return AppUser(
      id: Json.toInt(j['id']) ?? 0,
      name: Json.str(j['name']),
      email: Json.str(j['email']),
      phone: Json.str(j['phone']),
      role: Json.toStr(j['role']),
      status: Json.toInt(j['status']),
      country: Json.toStr(j['country']),
      city: Json.toStr(j['city']),
      selfie: Json.toStr(j['selfie']),
      identity: Json.toStr(j['identity']),
      referralCode: Json.toStr(j['rcode']),
      wallet: Json.toInt(j['wallet']),
      treesSaved: Json.toDouble(j['trees_saved']),
      carriedPackagesCount: Json.toInt(j['carried_packages_count']),
      packagesCount: Json.toInt(j['packages_count']),
      averageRating: Json.toDouble(j['average_rating']),
      ratingsCount: Json.toInt(j['ratings_count']),
    );
  }

  /// Round-trips a user through the preference cache.
  static Map<String, dynamic> toJson(AppUser u) => {
    'id': u.id,
    'name': u.name,
    'email': u.email,
    'phone': u.phone,
    'role': u.role,
    'status': u.status,
    'country': u.country,
    'city': u.city,
    'selfie': u.selfie,
    'identity': u.identity,
    'rcode': u.referralCode,
    'wallet': u.wallet,
    'trees_saved': u.treesSaved,
    'carried_packages_count': u.carriedPackagesCount,
    'packages_count': u.packagesCount,
    'average_rating': u.averageRating,
    'ratings_count': u.ratingsCount,
  };
}

abstract final class OrderAddressMapper {
  static OrderAddress fromOrderJson(Map<String, dynamic> j, String prefix) {
    return OrderAddress(
      name: Json.str(j['${prefix}_addressname']),
      city: Json.toStr(j['${prefix}_city']),
      country: Json.str(j['${prefix}_country']),
      cityAr: Json.toStr(j['${prefix}_city_ar']),
      countryAr: Json.toStr(j['${prefix}_country_ar']),
      lat: Json.toDouble(j['${prefix}_lat']) ?? 0,
      lng: Json.toDouble(j['${prefix}_lng']) ?? 0,
      street: Json.str(j['${prefix}_street']),
      building: Json.str(j['${prefix}_building']),
      apartment: Json.str(j['${prefix}_apartment']),
      notes: Json.toStr(j['${prefix}_notes']),
    );
  }

  static Map<String, dynamic> toJson(OrderAddress a) => {
    'name': a.name,
    'street': a.street,
    'building': a.building,
    'apartment': a.apartment,
    'city': a.city,
    'country': a.country,
    'lat': a.lat,
    'lng': a.lng,
    'notes': a.notes,
    'save': a.save,
  };
}

abstract final class ParcelOrderMapper {
  static ParcelOrder fromJson(Map<String, dynamic> j) {
    return ParcelOrder(
      id: Json.toInt(j['id']) ?? 0,
      userId: Json.toInt(j['user_id']) ?? 0,
      carrierId: Json.toInt(j['carrier_id']),
      status: ParcelOrderStatus.fromWire(Json.toStr(j['status'])),
      categoryId: Json.toInt(j['cate_id']),
      categoryName: Json.toStr(j['cate_name']),
      categoryNameAr: Json.toStr(j['cate_name_ar']),
      categoryImage: Json.toStr(j['cate_image']),
      sender: OrderAddressMapper.fromOrderJson(j, 's'),
      receiver: OrderAddressMapper.fromOrderJson(j, 'r'),
      senderName: _unquote(Json.str(j['s_name'])),
      senderPhone: _unquote(Json.str(j['s_phone'])),
      receiverName: _unquote(Json.str(j['r_name'])),
      receiverPhone: _unquote(Json.str(j['r_phone'])),
      type: Json.toInt(j['type']),
      paymentMethod: Json.toStr(j['payment_method']),
      paymentStatus: Json.toStr(j['payment_status']),
      paymentAmount: Json.toDouble(j['payment_amount']),
      paymentCurrency: Json.toStr(j['payment_currency']),
      notes: Json.toStr(j['notes']),
      value: Json.toStr(j['value']),
      weight: Json.toStr(j['weight']),
      amount: Json.toStr(j['amount']),
      description: Json.toStr(j['description']),
      orderDate: Json.toDate(j['order_date']),
      createdAt: Json.toDate(j['created_at']),
      updatedAt: Json.toDate(j['updated_at']),
      distanceKm: Json.toDouble(j['distance_km']),
      co2SavedPercent: Json.toDouble(j['co2_saved_percent']),
      treesSaved: Json.toDouble(j['trees_saved']),
      carrierName: Json.toStr(j['carrier_name']) ?? Json.toStr(j['cname']),
      carrierSelfie: Json.toStr(j['carrier_selfie']),
      carrierPhone: Json.toStr(j['carrier_phone']),
      carrierAverageRating: Json.toDouble(j['carrier_average_rating']),
      carrierRatingsCount: Json.toInt(j['carrier_ratings_count']),
      clientName: Json.toStr(j['client_name']),
      clientPhone: Json.toStr(j['client_phone']),
      isRead: j.containsKey('is_read') ? Json.toBool(j['is_read']) : null,
    );
  }

  /// Old rows stored names JSON-quoted (`"Rim"`); strip the quotes.
  static String _unquote(String s) {
    var out = s.trim();
    if (out.length >= 2 && out.startsWith('"') && out.endsWith('"')) {
      out = out.substring(1, out.length - 1);
    }
    return out;
  }

  static Map<String, dynamic> draftToJson(ParcelOrderDraft d) => {
    if (d.orderId != null) 'order_id': d.orderId,
    if (d.orderId != null) 'id': d.orderId,
    'payment_method': d.paymentMethodId,
    'user_id': d.userId,
    'cate_id': d.categoryId,
    'amount': d.reward,
    'price': d.reward,
    'value': d.value,
    'weight': d.weight,
    'r_name': d.receiverName,
    's_name': d.senderName,
    'r_phone': d.receiverPhone.replaceAll(RegExp(r'\s+'), ''),
    's_phone': d.senderPhone.replaceAll(RegExp(r'\s+'), ''),
    'notes': d.notes,
    'km': d.distanceKm,
    'description': d.description,
    'type': d.flow.type,
    'date_to': Json.dateOnly(d.neededBefore) ?? 'Needed Soon',
    's_address': OrderAddressMapper.toJson(d.sender),
    'r_address': OrderAddressMapper.toJson(d.receiver),
  };
}

abstract final class TripMapper {
  static TripCity _city(Object? value) {
    if (value is! Map) return const TripCity(id: null, name: '');
    final j = value.cast<String, dynamic>();
    final country = j['country'];
    final countryMap = country is Map ? country.cast<String, dynamic>() : null;
    return TripCity(
      id: Json.toInt(j['id']),
      name: Json.str(j['name']),
      nameAr: Json.toStr(j['name_ar']),
      countryId: Json.toInt(countryMap?['id']),
      countryName: Json.toStr(countryMap?['name']),
      countryNameAr: Json.toStr(countryMap?['name_ar']),
      image: Json.toStr(j['image']),
    );
  }

  static Trip fromJson(Map<String, dynamic> j) {
    return Trip(
      id: Json.toInt(j['trip_id']) ?? Json.toInt(j['id']) ?? 0,
      carrierId: Json.toInt(j['carrier_id']) ?? 0,
      frequency: TripFrequency.fromWire(Json.toStr(j['frequency'])),
      date: Json.toDate(j['date']),
      destinationImage: Json.toStr(j['destination_image']),
      from: _city(j['city_from']),
      to: _city(j['city_to']),
    );
  }

  static Map<String, dynamic> inputToJson(TripInput t) => {
    'city_from_id': t.cityFromId,
    'city_to_id': t.cityToId,
    'carrier_id': t.carrierId,
    'frequency': t.frequency.wire,
    'date': t.frequency == TripFrequency.oneTime ? Json.dateOnly(t.date) : null,
  };
}

abstract final class AddressMapper {
  static Address fromJson(Map<String, dynamic> j) {
    return Address(
      id: Json.toInt(j['id']) ?? 0,
      name: Json.str(j['name']),
      city: Json.toStr(j['city']),
      country: Json.str(j['country']),
      cityAr: Json.toStr(j['city_ar']),
      countryAr: Json.toStr(j['country_ar']),
      lat: Json.toDouble(j['lat']) ?? 0,
      lng: Json.toDouble(j['lng']) ?? 0,
      street: Json.str(j['street']),
      building: Json.str(j['building']),
      apartment: Json.str(j['apartment']),
      notes: Json.toStr(j['notes']),
      type: Json.toInt(j['type']) ?? 0,
    );
  }

  static Map<String, dynamic> inputToJson(AddressInput a) => {
    'user_id': a.userId,
    'name': a.name,
    'city': a.city,
    'country': a.country,
    'lat': a.lat,
    'lng': a.lng,
    'street': a.street,
    'building': a.building,
    'apartment': a.apartment,
    'notes': a.notes,
    'type': a.type,
  };
}

abstract final class CatalogMapper {
  static Country country(Map<String, dynamic> j) => Country(
    id: Json.toInt(j['id']) ?? 0,
    name: Json.str(j['name']),
    code: Json.toStr(j['code']),
    phoneCode: Json.toStr(j['phone_code']),
    flag: Json.toStr(j['flag']),
    nameAr: Json.toStr(j['name_ar']),
  );

  static City city(Map<String, dynamic> j) => City(
    id: Json.toInt(j['id']) ?? 0,
    name: Json.str(j['name']),
    countryId: Json.toInt(j['country_id']) ?? 0,
    image: Json.toStr(j['image']),
    nameAr: Json.toStr(j['name_ar']),
  );

  static ParcelCategory parcelCategory(Map<String, dynamic> j) =>
      ParcelCategory(
        id: Json.toInt(j['id']) ?? 0,
        name: Json.str(j['name']),
        text: Json.toStr(j['text']),
        image: Json.toStr(j['img']),
        sortNo: Json.toInt(j['sort_no']) ?? 0,
        nameAr: Json.toStr(j['name_ar']),
      );

  static AppService service(Map<String, dynamic> j) => AppService(
    id: Json.toInt(j['id']) ?? 0,
    name: Json.str(j['name']),
    nameAr: Json.toStr(j['name_ar']),
    image: Json.toStr(j['img']),
    sortNo: Json.toInt(j['sort_no']) ?? 0,
  );

  static SliderImage slider(Map<String, dynamic> j) => SliderImage(
    id: Json.toInt(j['id']) ?? 0,
    image: Json.str(j['img']),
    imageAr: Json.toStr(j['img_ar']),
    sortNo: Json.toInt(j['sort_no']) ?? 0,
  );

  static PaymentMethod paymentMethod(Map<String, dynamic> j) => PaymentMethod(
    id: Json.toInt(j['id']) ?? 0,
    name: Json.str(j['name']),
    code: Json.str(j['code']),
    currency: Json.str(j['currency'], 'USD'),
    publishableKey: Json.toStr(j['publishable_key']),
  );

  static AppSettings appSettings(Map<String, dynamic> j) => AppSettings(
    shuftiEnabled: j.containsKey('shufti_enabled')
        ? Json.toBool(j['shufti_enabled'])
        : true,
  );

  static AppVersionInfo appVersion(Map<String, dynamic> j) => AppVersionInfo(
    android: Json.toStr(j['android']),
    ios: Json.toStr(j['ios']),
  );

  static AppTexts texts(Object? body) {
    if (body is! Map) return const AppTexts.empty();
    final out = <String, String>{};
    body.forEach((k, v) {
      if (v != null) out[k.toString()] = v.toString();
    });
    return AppTexts(out);
  }
}
