import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/reservation_repository.dart';
import 'reservation_state.dart';

class ReservationCubit extends Cubit<ReservationState> {
  final ReservationRepository _repository;

  ReservationCubit(this._repository) : super(const ReservationInitial());

  Future<void> loadReservations() async {
    emit(const ReservationLoading());
    try {
      final reservations = await _repository.getMyReservations();
      emit(ReservationLoaded(reservations));
    } catch (error) {
      emit(ReservationError(_messageFromError(error)));
    }
  }

  Future<void> refreshReservations() async {
    try {
      final reservations = await _repository.getMyReservations();
      emit(ReservationLoaded(reservations));
    } catch (error) {
      emit(ReservationError(_messageFromError(error)));
    }
  }

  Future<void> cancelReservation(String id) async {
    final currentState = state;
    if (currentState is! ReservationLoaded) return;

    emit(currentState.copyWith(cancellingId: id));
    try {
      await _repository.cancelReservation(id);
      final reservations = await _repository.getMyReservations();
      emit(ReservationLoaded(reservations));
    } catch (error) {
      emit(
        currentState.copyWith(
          cancellingId: null,
          actionError: _messageFromError(error),
        ),
      );
    }
  }

  String _messageFromError(Object error) {
    final message = error.toString();
    return message.replaceFirst('Exception: ', '');
  }
}
