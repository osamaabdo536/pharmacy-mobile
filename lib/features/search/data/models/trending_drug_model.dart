import 'pharmacy_result_model.dart';

class TrendingDrugModel {
  final String id;
  final String name;
  final String? genericName;
  final String? activeIngredient;
  final String? category;
  final String? strength;
  final String? dosageForm;
  final String? manufacturer;
  final double? price;
  final List<PharmacyResultModel> pharmacies;
  final bool hasPharmacyResults;

  TrendingDrugModel({
    required this.id,
    required this.name,
    this.genericName,
    this.activeIngredient,
    this.category,
    this.strength,
    this.dosageForm,
    this.manufacturer,
    this.price,
    this.pharmacies = const [],
    this.hasPharmacyResults = false,
  });

  String get displayName {
    final parts = [
      name,
      strength,
      dosageForm,
    ].where((part) => part != null && part.isNotEmpty).cast<String>().toList();
    return parts.join(' ');
  }

  factory TrendingDrugModel.fromJson(Map<String, dynamic> json) {
    return TrendingDrugModel(
      id:
          json['drug_id']?.toString() ??
          json['drugId']?.toString() ??
          json['id']?.toString() ??
          json['_id']?.toString() ??
          '',
      name:
          json['brand_name'] as String? ??
          json['brandName'] as String? ??
          json['name'] as String? ??
          json['generic_name'] as String? ??
          json['genericName'] as String? ??
          'Medicine',
      genericName:
          json['generic_name'] as String? ?? json['genericName'] as String?,
      activeIngredient:
          json['active_ingredient'] as String? ??
          json['activeIngredient'] as String?,
      category: json['category'] as String?,
      strength: json['strength'] as String?,
      dosageForm:
          json['dosage_form'] as String? ?? json['dosageForm'] as String?,
      manufacturer: json['manufacturer'] as String?,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : null,
      pharmacies: _parsePharmacies(json['pharmacies']),
      hasPharmacyResults: json.containsKey('pharmacies'),
    );
  }

  static List<PharmacyResultModel> _parsePharmacies(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final pharmacies = value
        .whereType<Map<String, dynamic>>()
        .map(PharmacyResultModel.fromJson)
        .where((pharmacy) => pharmacy.isAvailable)
        .toList();

    return _dedupeByPharmacyKeepingCheapest(pharmacies);
  }

  static List<PharmacyResultModel> _dedupeByPharmacyKeepingCheapest(
    List<PharmacyResultModel> pharmacies,
  ) {
    final byPharmacy = <String, PharmacyResultModel>{};

    for (final pharmacy in pharmacies) {
      final key = pharmacy.pharmacyId.isNotEmpty
          ? pharmacy.pharmacyId
          : pharmacy.id;
      final current = byPharmacy[key];

      if (current == null) {
        byPharmacy[key] = pharmacy;
        continue;
      }

      final totalStock =
          (current.stockQuantity ?? 0) + (pharmacy.stockQuantity ?? 0);
      final cheaper = pharmacy.price < current.price ? pharmacy : current;

      byPharmacy[key] = cheaper.copyWith(stockQuantity: totalStock);
    }

    return byPharmacy.values.toList();
  }
}
