import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy_mobile/features/auth/data/models/auth_repository.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/notification_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit(this._repository) : super(const AuthInitial());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    final result = await _repository.login(email: email, password: password);
    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) {
        emit(AuthAuthenticated(user));
        _registerFcmToken();
      },
    );
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    emit(const AuthLoading());
    final result = await _repository.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );
    result.fold(
          (failure) {
        if (failure is EmailConfirmationFailure) {
          emit(AuthEmailConfirmationRequired(failure.message));
        } else {
          emit(AuthError(failure.message));
        }
      },
          (user) {
        emit(AuthAuthenticated(user));
        _registerFcmToken();
      },
    );
  }

  /// Called from SplashScreen if a token already exists, to validate it
  /// and restore the user session.
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());
    final result = await _repository.getCurrentUser();
    result.fold(
          (_) => emit(const AuthUnauthenticated()),
          (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }


  void _registerFcmToken() async {
    try {
      final token = await NotificationService.getToken();
      if (token == null) return;
      await DioClient.instance.patch(
        ApiConstants.updateFcmToken,
        data: {'fcm_token': token},
      );
    } catch (_) {
      // non-critical — don't block the login flow
    }
  }
}