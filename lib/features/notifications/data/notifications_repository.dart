import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import 'models/notification_model.dart';

class NotificationsRepository {
  NotificationsRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  Future<Either<Failure, List<NotificationModel>>> getMyNotifications() async {
    try {
      final response = await _dio.get(ApiConstants.myNotifications);
      final rawData = response.data is Map<String, dynamic>
          ? response.data['data']
          : response.data;

      if (rawData is! List) {
        return const Right([]);
      }

      final notifications = rawData
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();

      return Right(notifications);
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  Future<Either<Failure, Unit>> markNotificationRead(String id) async {
    try {
      await _dio.patch(ApiConstants.markNotificationRead(id));
      return const Right(unit);
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  Future<Either<Failure, Unit>> markAllRead(List<String> ids) async {
    if (ids.isEmpty) return const Right(unit);

    for (final id in ids) {
      final result = await markNotificationRead(id);
      if (result.isLeft()) {
        return result;
      }
    }

    return const Right(unit);
  }
}

