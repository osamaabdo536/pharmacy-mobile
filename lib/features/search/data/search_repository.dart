import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/pharmacy_result_model.dart';
import 'models/trending_drug_model.dart';

class SearchRepository {
  final Dio _dio = DioClient.instance;

  Future<List<TrendingDrugModel>> getTrending({int limit = 8}) async {
    final response = await _dio.get(
      ApiConstants.drugTrending,
      queryParameters: {'limit': limit},
    );

    final rawData = _extractList(response.data);

    if (rawData is! List) {
      return [];
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map(TrendingDrugModel.fromJson)
        .toList();
  }

  Future<List<TrendingDrugModel>> searchDrugs(
    String query, {
    required double lat,
    required double lng,
    double radius = 100,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    final response = await _dio.get(
      ApiConstants.drugSearch,
      queryParameters: {'q': trimmed, 'lat': lat, 'lng': lng, 'radius': radius},
    );

    final rawData = _extractList(response.data);

    if (rawData is! List) {
      return [];
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map(TrendingDrugModel.fromJson)
        .where((drug) => drug.id.isNotEmpty)
        .toList();
  }

  Future<List<PharmacyResultModel>> getNearbyPharmacies(
    String drugId, {
    required double lat,
    required double lng,
    double radius = 10,
  }) async {
    final response = await _dio.get(
      ApiConstants.drugNearby(drugId),
      queryParameters: {'lat': lat, 'lng': lng, 'radius': radius},
    );
    final rawData = _extractList(response.data);

    if (rawData is! List) {
      return [];
    }

    final inventory = rawData
        .whereType<Map<String, dynamic>>()
        .map(PharmacyResultModel.fromJson)
        .where(
          (item) =>
              item.isAvailable &&
              (item.drugId.isEmpty || item.drugId == drugId),
        )
        .toList();

    return _dedupeByPharmacyKeepingNearestOrder(inventory);
  }

  List<PharmacyResultModel> _dedupeByPharmacyKeepingNearestOrder(
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

  List<dynamic>? _extractList(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    if (payload is! Map<String, dynamic>) {
      return null;
    }

    for (final key in ['data', 'items', 'results', 'drugs', 'inventory']) {
      final value = payload[key];

      if (value is List) {
        return value;
      }

      if (value is Map<String, dynamic>) {
        final nested = _extractList(value);
        if (nested != null) {
          return nested;
        }
      }
    }

    return null;
  }
}
