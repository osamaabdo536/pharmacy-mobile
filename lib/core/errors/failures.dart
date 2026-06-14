import 'package:equatable/equatable.dart';

/// Base class for all failures in the app.
/// Used with dartz's Either<Failure, T> as the "Left" side.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Returned when the server responds with 5xx,
/// or with an error shape we can't recover from.
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Something went wrong, please try again'])
      : super(message);
}

/// Returned when there's no internet connection,
/// or Dio throws a connection/timeout error.
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Please check your internet connection'])
      : super(message);
}

/// Returned on 401/403 — invalid or expired token,
/// or user role isn't 'user'.
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Session expired, please log in again'])
      : super(message);
}

/// Returned for 404 / "not found" type responses
/// (e.g. drug not found, reservation not found).
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'The requested item was not found'])
      : super(message);
}

/// Not a real "error" — sign-up succeeded, but the user must verify
/// their email before they can log in.
class EmailConfirmationFailure extends Failure {
  const EmailConfirmationFailure([
    String message =
    'Account created. Please check your email to verify your account before logging in.',
  ]) : super(message);
}