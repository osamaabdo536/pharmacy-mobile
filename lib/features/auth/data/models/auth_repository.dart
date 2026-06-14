import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:pharmacy_mobile/features/auth/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/local_storage.dart';


class AuthRepository {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  Future<Either<Failure, UserModel>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phone,
        },
      );

      final session = response.session;
      if (session == null) {
        // Supabase project has "Confirm email" enabled — no session
        // until the user verifies their email.
        return const Left(EmailConfirmationFailure());
      }

      await TokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
      );

      return _fetchRoleAndValidate();
    } on supabase.AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(NetworkFailure());
    }
  }

  Future<Either<Failure, UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      if (session == null) {
        return const Left(AuthFailure('Invalid email or password'));
      }

      await TokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
      );

      return _fetchRoleAndValidate();
    } on supabase.AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(NetworkFailure());
    }
  }

  Future<Either<Failure, UserModel>> getCurrentUser() async {
    if (!TokenStorage.hasToken()) {
      return const Left(AuthFailure('Not logged in'));
    }
    return _fetchRoleAndValidate();
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // ignore — local tokens are cleared regardless
    }
    await TokenStorage.clearTokens();
  }

  Future<Either<Failure, UserModel>> _fetchRoleAndValidate() async {
    try {
      final response = await DioClient.instance.post(ApiConstants.authRole);
      final data = response.data['data'] as Map<String, dynamic>;
      final role = data['role'] as String;

      final supabaseUser = _supabase.auth.currentUser;
      if (supabaseUser == null) {
        return const Left(AuthFailure('Session expired, please log in again'));
      }

      final user = UserModel.fromSupabaseUser(supabaseUser, role);

      if (user.role != 'user') {
        await logout();
        return const Left(
          AuthFailure('This account does not have access to this app.'),
        );
      }

      return Right(user);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await logout();
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}