import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import 'models/chat_history_message.dart';
import 'models/chat_response.dart';

class ChatRepository {
  final Dio _dio = DioClient.instance;

  /// Sends a message to POST /ai/chat and returns the AI reply + updated history.
  Future<Either<Failure, ChatResponse>> sendMessage({
    required String message,
    required List<ChatHistoryMessage> history,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.aiChat,
        data: {
          'message': message,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (history.isNotEmpty)
            'conversationHistory': history.map((h) => h.toJson()).toList(),
        },
      );

      return Right(ChatResponse.fromJson(response.data['data']));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
