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

    final rawData = response.data is Map<String, dynamic>
        ? response.data['data'] ??
              response.data['items'] ??
              response.data['results']
        : response.data;

    if (rawData is! List) {
      return [];
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map(TrendingDrugModel.fromJson)
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
    final rawData = response.data is Map<String, dynamic>
        ? response.data['data'] ??
              response.data['items'] ??
              response.data['results']
        : response.data;

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
}
