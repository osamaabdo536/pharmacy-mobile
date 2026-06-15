import '../data/models/reservation_model.dart';

sealed class ReservationState {
  const ReservationState();
}

class ReservationInitial extends ReservationState {
  const ReservationInitial();
}

class ReservationLoading extends ReservationState {
  const ReservationLoading();
}

class ReservationLoaded extends ReservationState {
  final List<ReservationModel> reservations;
  final String? cancellingId;
  final String? actionError;

  const ReservationLoaded(
    this.reservations, {
    this.cancellingId,
    this.actionError,
  });

  ReservationLoaded copyWith({
    List<ReservationModel>? reservations,
    Object? cancellingId = _sentinel,
    Object? actionError = _sentinel,
  }) {
    return ReservationLoaded(
      reservations ?? this.reservations,
      cancellingId: cancellingId == _sentinel
          ? this.cancellingId
          : cancellingId as String?,
      actionError: actionError == _sentinel
          ? this.actionError
          : actionError as String?,
    );
  }

  static const Object _sentinel = Object();
}

class ReservationError extends ReservationState {
  final String message;

  const ReservationError(this.message);
}
