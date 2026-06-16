import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../errors/failures.dart';
import '../storage/local_storage.dart';

/// Singleton Dio client for the NestJS backend.
///
/// NOTE: This is NOT used for Supabase auth calls (signup/login/logout/
/// refresh) — those go through `supabase_flutter` directly. This client
/// is for everything under [ApiConstants.baseUrl] that requires the
/// Supabase JWT as a Bearer token.
class DioClient {
  DioClient._();

  static Dio? _dio;

  static Dio get instance {
    _dio ??= _create();
    return _dio!;
  }

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(_authInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }

  static InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = TokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // 401 → token invalid/expired. Clear it locally.
        // GoRouter's redirect (LocalStorage.hasToken()) will pick this up
        // on next navigation — we'll wire the live refresh when building
        // app.dart's router.
        if (error.response?.statusCode == 401) {
          await TokenStorage.clearTokens();
        }
        return handler.next(error);
      },
    );
  }
}

/// Maps a [DioException] to a [Failure] for use with dartz's Either
/// in repositories.
///
/// Usage in a repository:
/// ```dart
/// try {
///   final response = await dio.get(...);
///   return Right(SomeModel.fromJson(response.data['data']));
/// } on DioException catch (e) {
///   return Left(mapDioExceptionToFailure(e));
/// }
/// ```
Failure mapDioExceptionToFailure(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();

    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final message = _extractErrorMessage(error.response?.data);

      if (statusCode == 401 || statusCode == 403) {
        return AuthFailure(message ?? const AuthFailure().message);
      }
      if (statusCode == 404) {
        return NotFoundFailure(message ?? const NotFoundFailure().message);
      }
      if (statusCode != null && statusCode >= 500) {
        return ServerFailure(message ?? const ServerFailure().message);
      }
      return ServerFailure(message ?? const ServerFailure().message);

    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return const NetworkFailure();
  }
}

/// Extracts the `error.message` field from the NestJS error shape:
/// `{ "error": { "code": "...", "message": "...", "timestamp": "..." } }`
String? _extractErrorMessage(dynamic responseData) {
  if (responseData is Map<String, dynamic>) {
    final error = responseData['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
  }
  return null;
}