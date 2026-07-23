import 'package:transient_team_ws/core/error/failure.dart';

/// Maps failures that can be shared by every feature in the application.
///
/// Data sources should convert package-specific exceptions (Dio, Firebase,
/// Hive, etc.) to one of these failures before returning from a repository.
final class DefaultFailure extends Failure {
  DefaultFailure({
    super.message = 'Something went wrong, please try again later.',
  });
}

final class NetworkFailure extends Failure {
  NetworkFailure({super.message = 'No internet connection. Please try again.'});
}

final class RequestTimeoutFailure extends Failure {
  RequestTimeoutFailure({
    super.message = 'The request timed out. Please try again.',
  });
}

final class UnauthorizedFailure extends Failure {
  UnauthorizedFailure({
    super.message = 'Your session has expired. Please sign in again.',
  });
}

final class ForbiddenFailure extends Failure {
  ForbiddenFailure({
    super.message = 'You do not have permission to perform this action.',
  });
}

final class NotFoundFailure extends Failure {
  NotFoundFailure({super.message = 'The requested item could not be found.'});
}

final class ConflictFailure extends Failure {
  ConflictFailure({
    super.message =
        'This item was changed elsewhere. Please refresh and try again.',
  });
}

final class ValidationFailure extends Failure {
  ValidationFailure({super.message = 'Please check the entered information.'});
}

final class RateLimitFailure extends Failure {
  RateLimitFailure({
    super.message = 'Too many requests. Please wait a moment and try again.',
  });
}

final class ServerFailure extends Failure {
  ServerFailure({
    super.message = 'The server is unavailable. Please try again later.',
  });
}

final class CacheReadFailure extends Failure {
  CacheReadFailure({super.message = 'Unable to load the saved data.'});
}

final class CacheWriteFailure extends Failure {
  CacheWriteFailure({super.message = 'Unable to save your changes locally.'});
}

final class ResponseParsingFailure extends Failure {
  ResponseParsingFailure({
    super.message = 'The response could not be read. Please try again.',
  });
}

final class AuthenticationFailure extends Failure {
  AuthenticationFailure({
    super.message = 'Authentication failed. Please try again.',
  });
}

/// Converts transport-level HTTP responses to domain-safe failures.
final class HttpFailureMapper {
  const HttpFailureMapper._();

  static Failure fromStatusCode(int? statusCode, {String? message}) {
    final failure = switch (statusCode) {
      null || 0 => NetworkFailure(),
      400 || 422 => ValidationFailure(),
      401 => UnauthorizedFailure(),
      403 => ForbiddenFailure(),
      404 => NotFoundFailure(),
      408 || 504 => RequestTimeoutFailure(),
      409 => ConflictFailure(),
      429 => RateLimitFailure(),
      >= 500 && <= 599 => ServerFailure(),
      _ => DefaultFailure(),
    };

    return message == null || message.isEmpty
        ? failure
        : _withMessage(failure, message);
  }

  static Failure _withMessage(Failure failure, String message) =>
      switch (failure) {
        NetworkFailure() => NetworkFailure(message: message),
        RequestTimeoutFailure() => RequestTimeoutFailure(message: message),
        UnauthorizedFailure() => UnauthorizedFailure(message: message),
        ForbiddenFailure() => ForbiddenFailure(message: message),
        NotFoundFailure() => NotFoundFailure(message: message),
        ConflictFailure() => ConflictFailure(message: message),
        ValidationFailure() => ValidationFailure(message: message),
        RateLimitFailure() => RateLimitFailure(message: message),
        ServerFailure() => ServerFailure(message: message),
        _ => DefaultFailure(message: message),
      };
}

/// Converts FirebaseAuthException.code values without coupling the domain layer
/// to the Firebase package. Call this with `exception.code` in the auth source.
final class FirebaseAuthFailureMapper {
  const FirebaseAuthFailureMapper._();

  static Failure fromCode(String code, {String? message}) {
    final failure = switch (code) {
      'invalid-email' || 'weak-password' => ValidationFailure(),
      'email-already-in-use' => ConflictFailure(
        message: 'An account already exists for this email address.',
      ),
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        AuthenticationFailure(message: 'Incorrect email or password.'),
      'user-disabled' => AuthenticationFailure(
        message: 'This account has been disabled.',
      ),
      'requires-recent-login' => UnauthorizedFailure(
        message: 'Please sign in again to continue.',
      ),
      'too-many-requests' => RateLimitFailure(),
      'network-request-failed' => NetworkFailure(),
      'operation-not-allowed' => ForbiddenFailure(),
      _ => AuthenticationFailure(),
    };

    return message == null || message.isEmpty
        ? failure
        : _withMessage(failure, message);
  }

  static Failure _withMessage(Failure failure, String message) =>
      switch (failure) {
        ValidationFailure() => ValidationFailure(message: message),
        ConflictFailure() => ConflictFailure(message: message),
        UnauthorizedFailure() => UnauthorizedFailure(message: message),
        RateLimitFailure() => RateLimitFailure(message: message),
        NetworkFailure() => NetworkFailure(message: message),
        ForbiddenFailure() => ForbiddenFailure(message: message),
        _ => AuthenticationFailure(message: message),
      };
}
