class TrendingDrugModel {
  final String id;
  final String name;
  final String? strength;
  final String? dosageForm;
  final String? manufacturer;
  final double? price;

  TrendingDrugModel({
    required this.id,
    required this.name,
    this.strength,
    this.dosageForm,
    this.manufacturer,
    this.price,
  });

  String get displayName {
    final parts = [name, strength, dosageForm]
        .where((part) => part != null && part!.isNotEmpty)
        .cast<String>()
        .toList();
    return parts.join(' ');
  }

  factory TrendingDrugModel.fromJson(Map<String, dynamic> json) {
    return TrendingDrugModel(
      id: json['drug_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['brand_name'] as String? ?? json['generic_name'] as String? ?? 'Medicine',
      strength: json['strength'] as String?,
      dosageForm: json['dosage_form'] as String?,
      manufacturer: json['manufacturer'] as String?,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : null,
    );
  }
}
