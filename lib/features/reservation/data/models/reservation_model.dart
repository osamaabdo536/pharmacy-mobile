class ReservationModel {
  final String id;
  final String shortCode;
  final String status;
  final int quantity;
  final double priceAtReservation;
  final double discountAtReservation;
  final double totalPrice;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? confirmedAt;
  final String pharmacyName;
  final String? pharmacyAddress;
  final String? drugName;
  final String? drugStrength;
  final String? dosageForm;

  const ReservationModel({
    required this.id,
    required this.shortCode,
    required this.status,
    required this.quantity,
    required this.priceAtReservation,
    required this.discountAtReservation,
    required this.totalPrice,
    required this.createdAt,
    required this.expiresAt,
    required this.confirmedAt,
    required this.pharmacyName,
    this.pharmacyAddress,
    this.drugName,
    this.drugStrength,
    this.dosageForm,
  });

  bool get canCancel => status.toLowerCase() == 'pending';

  String get normalizedStatus => status.toLowerCase();

  double get discountPercentage {
    if (discountAtReservation > 0) return discountAtReservation;

    final baseTotal = priceAtReservation * quantity;
    if (baseTotal <= 0 || totalPrice >= baseTotal) return 0;
    return ((baseTotal - totalPrice) / baseTotal) * 100;
  }

  bool get hasDiscount => discountPercentage > 0;

  int get roundedDiscount => discountPercentage.round();

  double get originalTotal {
    final baseTotal = priceAtReservation * quantity;
    if (baseTotal > 0) return baseTotal;
    if (!hasDiscount || discountPercentage >= 100) return totalPrice;
    return totalPrice / (1 - (discountPercentage / 100));
  }

  String get displayDrug {
    final parts = [drugName, drugStrength, dosageForm]
        .where((part) => part != null && part.trim().isNotEmpty)
        .cast<String>()
        .toList();
    return parts.isEmpty ? 'Reserved medicine' : parts.join(' ');
  }

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final inventory = _asMap(json['inventory']);
    final pharmacy = _asMap(inventory?['pharmacy']);
    final drug = _asMap(inventory?['drug']);

    return ReservationModel(
      id: _asString(json['id']),
      shortCode: _asString(json['short_code'], fallback: 'MC-0000'),
      status: _asString(json['status'], fallback: 'pending'),
      quantity: _asInt(json['quantity']),
      priceAtReservation: _asDouble(json['price_at_reservation']),
      discountAtReservation: _asDouble(json['discount_at_reservation']),
      totalPrice: _asDouble(json['total_price']),
      createdAt: _asDate(json['created_at']),
      expiresAt: _asDate(json['expires_at']),
      confirmedAt: _asDate(json['confirmed_at']),
      pharmacyName: _asString(pharmacy?['pharmacy_name'], fallback: 'Pharmacy'),
      pharmacyAddress: _nullableString(pharmacy?['address']),
      drugName:
          _nullableString(drug?['brand_name']) ??
          _nullableString(drug?['brand_name_ar']) ??
          _nullableString(drug?['generic_name']),
      drugStrength: _nullableString(drug?['strength']),
      dosageForm: _nullableString(drug?['dosage_form']),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    return value is String && value.isNotEmpty ? value : fallback;
  }

  static String? _nullableString(dynamic value) {
    return value is String && value.isNotEmpty ? value : null;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDate(dynamic value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
