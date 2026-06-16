class PharmacyResultModel {
  final String id;
  final String pharmacyId;
  final String drugId;
  final String name;
  final String? address;
  final double? distanceKm;
  final double price;
  final double? originalPrice;
  final int? discountPercent;
  final int? stockQuantity;
  final String? status;

  const PharmacyResultModel({
    required this.id,
    required this.pharmacyId,
    required this.drugId,
    required this.name,
    this.address,
    this.distanceKm,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    this.stockQuantity,
    this.status,
  });

  bool get isAvailable {
    final normalizedStatus = status?.toLowerCase();
    final active = normalizedStatus == null || normalizedStatus == 'active';
    final inStock = stockQuantity == null || stockQuantity! > 0;
    return active && inStock;
  }

  String get distanceLabel {
    if (distanceKm == null) return '';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  double? get displayOriginalPrice {
    if (originalPrice != null && originalPrice! > price) {
      return originalPrice;
    }

    if (discountPercent != null &&
        discountPercent! > 0 &&
        discountPercent! < 100) {
      return price / (1 - (discountPercent! / 100));
    }

    return null;
  }

  int? get displayDiscountPercent {
    if (discountPercent != null && discountPercent! > 0) {
      return discountPercent;
    }

    final oldPrice = displayOriginalPrice;
    if (oldPrice == null || oldPrice <= 0) return null;

    final discount = ((oldPrice - price) / oldPrice * 100).round();
    return discount > 0 ? discount : null;
  }

  factory PharmacyResultModel.fromJson(Map<String, dynamic> json) {
    final pharmacy = _asMap(json['pharmacy']);
    final inventory = _asMap(json['inventory']) ?? json;
    final finalPrice = _nullableDouble(
      json['final_price'] ?? json['finalPrice'] ?? inventory['final_price'],
    );
    final sellingPrice = _nullableDouble(
      json['selling_price'] ??
          json['price'] ??
          json['unit_price'] ??
          json['sale_price'] ??
          json['price_per_unit'] ??
          json['current_price'] ??
          inventory['selling_price'] ??
          inventory['price'] ??
          inventory['unit_price'] ??
          inventory['price_per_unit'],
    );

    return PharmacyResultModel(
      id: _asString(
        json['inventory_id'] ??
            json['id'] ??
            inventory['id'] ??
            pharmacy?['id'],
      ),
      pharmacyId: _asString(
        json['pharmacy_id'] ??
            inventory['pharmacy_id'] ??
            pharmacy?['id'] ??
            json['pharmacyId'],
      ),
      drugId: _asString(
        json['drug_id'] ??
            inventory['drug_id'] ??
            json['drugId'] ??
            inventory['drugId'] ??
            _asMap(json['drug'])?['id'],
      ),
      name: _asString(
        json['pharmacy_name'] ??
            json['name'] ??
            json['pharmacyName'] ??
            pharmacy?['pharmacy_name'] ??
            pharmacy?['pharmacyName'] ??
            pharmacy?['name'],
        fallback: _pharmacyFallbackName(
          json['pharmacy_id'] ?? inventory['pharmacy_id'] ?? pharmacy?['id'],
        ),
      ),
      address: _nullableString(
        json['address'] ??
            json['pharmacy_address'] ??
            json['pharmacyAddress'] ??
            pharmacy?['address'] ??
            pharmacy?['location'],
      ),
      distanceKm: _distanceKm(
        json['distance_miles'] ??
            json['distanceMiles'] ??
            json['distance'] ??
            pharmacy?['distance_miles'],
        json['distance_km'] ?? json['distanceKm'] ?? pharmacy?['distance_km'],
        json['distance_meters'] ??
            json['distanceMeters'] ??
            pharmacy?['distance_meters'],
      ),
      price: _asDouble(finalPrice ?? sellingPrice),
      originalPrice: _nullableDouble(
        json['original_price'] ??
            json['originalPrice'] ??
            json['list_price'] ??
            json['retail_price'] ??
            inventory['original_price'] ??
            inventory['list_price'] ??
            inventory['retail_price'] ??
            (finalPrice != null &&
                    sellingPrice != null &&
                    finalPrice < sellingPrice
                ? sellingPrice
                : null),
      ),
      discountPercent: _nullableInt(
        json['discount'] ??
            json['discount_percent'] ??
            json['discountPercent'] ??
            json['discount_percentage'] ??
            inventory['discount_percent'] ??
            inventory['discount_percentage'],
      ),
      stockQuantity: _nullableInt(
        json['stock'] ??
            json['stock_quantity'] ??
            json['quantity'] ??
            inventory['stock_quantity'] ??
            inventory['quantity'],
      ),
      status: _nullableString(json['status'] ?? inventory['status']),
    );
  }

  PharmacyResultModel copyWith({
    String? id,
    String? pharmacyId,
    String? drugId,
    String? name,
    String? address,
    double? distanceKm,
    double? price,
    double? originalPrice,
    int? discountPercent,
    int? stockQuantity,
    String? status,
  }) {
    return PharmacyResultModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      drugId: drugId ?? this.drugId,
      name: name ?? this.name,
      address: address ?? this.address,
      distanceKm: distanceKm ?? this.distanceKm,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      status: status ?? this.status,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text != null && text.isNotEmpty ? text : fallback;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text != null && text.isNotEmpty ? text : null;
  }

  static double _asDouble(dynamic value) {
    return _nullableDouble(value) ?? 0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _nullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _distanceKm(
    dynamic milesValue,
    dynamic kmValue,
    dynamic metersValue,
  ) {
    final kilometers = _nullableDouble(kmValue);
    if (kilometers != null) return kilometers;

    final miles = _nullableDouble(milesValue);
    if (miles != null) return miles * 1.60934;

    final meters = _nullableDouble(metersValue);
    if (meters == null) return null;
    return meters / 1000;
  }

  static String _pharmacyFallbackName(dynamic pharmacyId) {
    final id = pharmacyId?.toString();
    if (id == null || id.isEmpty) return 'Pharmacy';
    return 'Pharmacy ${id.substring(0, id.length < 8 ? id.length : 8)}';
  }
}
