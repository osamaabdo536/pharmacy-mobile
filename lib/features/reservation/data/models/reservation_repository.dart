import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import 'reservation_model.dart';

class ReservationRepository {
  final _dio = DioClient.instance;

  Future<List<ReservationModel>> getMyReservations() async {
    final response = await _dio.get(ApiConstants.myReservations);
    final rawData = response.data is Map<String, dynamic>
        ? response.data['data']
        : response.data;

    if (rawData is! List) {
      return [];
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map(ReservationModel.fromJson)
        .toList();
  }

  Future<ReservationModel> cancelReservation(String id) async {
    final response = await _dio.delete(ApiConstants.cancelReservation(id));
    final rawData = response.data is Map<String, dynamic>
        ? response.data['data']
        : response.data;

    if (rawData is! Map<String, dynamic>) {
      throw StateError('Invalid reservation response');
    }

    return ReservationModel.fromJson(rawData);
  }
}
