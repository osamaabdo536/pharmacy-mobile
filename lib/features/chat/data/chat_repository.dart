import 'dart:convert';

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
      // Receive as plain string so we can sanitize before JSON parsing.
      // This prevents Bad UTF-8 crashes from special characters in drug names.
      final response = await _dio.post(
        ApiConstants.aiChat,
        options: Options(responseType: ResponseType.plain),
        data: {
          'message': message,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (history.isNotEmpty)
            'conversationHistory': history.map((h) => h.toJson()).toList(),
        },
      );

      // Sanitize: replace UTF-8 replacement character and other
      // problematic characters that come from drug name data.
      final rawString = (response.data as String)
          .replaceAll(
            '\uFFFD',
            '',
          ) // UTF-8 replacement character (◆ encoded badly)
          .replaceAll('\u25C6', ' ') // ◆ black diamond
          .replaceAll('\u0000', ''); // null bytes

      final jsonMap = json.decode(rawString) as Map<String, dynamic>;
      return Right(ChatResponse.fromJson(jsonMap['data']));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (e) {
      return const Left(
        ServerFailure('Something went wrong, please try again'),
      );
    }
  }
}
