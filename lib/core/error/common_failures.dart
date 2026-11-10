import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:transient_team_ws/core/error/failure.dart';

/// A stable error category for presentation code to react to.
enum FailureType {
  unknown,
  network,
  timeout,
  requestCancelled,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimit,
  server,
  cacheRead,
  cacheWrite,
  responseParsing,
  authentication,
  accountInactive,
}

/// Base failure used across all features.
///
/// `message` is safe to show in the UI. Keep the original error in [cause]
/// for logging only; never render it directly because it can expose server or
/// Firebase implementation details.
class AppFailure extends Failure {
  AppFailure({
    required this.type,
    required super.message,
    this.statusCode,
    this.cause,
  });

  final FailureType type;
  final int? statusCode;
  final Object? cause;
}

final class DefaultFailure extends AppFailure {
  DefaultFailure({super.cause, String? message})
    : super(
        type: FailureType.unknown,
        message: message ?? AppErrorMessages.unknown,
      );
}

final class NetworkFailure extends AppFailure {
  NetworkFailure({super.cause, String? message})
    : super(
        type: FailureType.network,
        message: message ?? AppErrorMessages.network,
      );
}

final class RequestTimeoutFailure extends AppFailure {
  RequestTimeoutFailure({super.cause, String? message})
    : super(
        type: FailureType.timeout,
        message: message ?? AppErrorMessages.timeout,
      );
}

final class RequestCancelledFailure extends AppFailure {
  RequestCancelledFailure({super.cause, String? message})
    : super(
        type: FailureType.requestCancelled,
        message: message ?? AppErrorMessages.requestCancelled,
      );
}

final class UnauthorizedFailure extends AppFailure {
  UnauthorizedFailure({super.cause, String? message})
    : super(
        type: FailureType.unauthorized,
        message: message ?? AppErrorMessages.unauthorized,
      );
}

final class ForbiddenFailure extends AppFailure {
  ForbiddenFailure({super.cause, String? message})
    : super(
        type: FailureType.forbidden,
        message: message ?? AppErrorMessages.forbidden,
      );
}

final class NotFoundFailure extends AppFailure {
  NotFoundFailure({super.cause, String? message})
    : super(
        type: FailureType.notFound,
        message: message ?? AppErrorMessages.notFound,
      );
}

final class ConflictFailure extends AppFailure {
  ConflictFailure({super.cause, String? message})
    : super(
        type: FailureType.conflict,
        message: message ?? AppErrorMessages.conflict,
      );
}

final class ValidationFailure extends AppFailure {
  ValidationFailure({super.cause, String? message})
    : super(
        type: FailureType.validation,
        message: message ?? AppErrorMessages.validation,
      );
}

final class RateLimitFailure extends AppFailure {
  RateLimitFailure({super.cause, String? message})
    : super(
        type: FailureType.rateLimit,
        message: message ?? AppErrorMessages.rateLimit,
      );
}

final class ServerFailure extends AppFailure {
  ServerFailure({super.cause, super.statusCode, String? message})
    : super(
        type: FailureType.server,
        message: message ?? AppErrorMessages.server,
      );
}

final class CacheReadFailure extends AppFailure {
  CacheReadFailure({super.cause, String? message})
    : super(
        type: FailureType.cacheRead,
        message: message ?? AppErrorMessages.cacheRead,
      );
}

final class CacheWriteFailure extends AppFailure {
  CacheWriteFailure({super.cause, String? message})
    : super(
        type: FailureType.cacheWrite,
        message: message ?? AppErrorMessages.cacheWrite,
      );
}

final class ResponseParsingFailure extends AppFailure {
  ResponseParsingFailure({super.cause, String? message})
    : super(
        type: FailureType.responseParsing,
        message: message ?? AppErrorMessages.responseParsing,
      );
}

final class AuthenticationFailure extends AppFailure {
  AuthenticationFailure({super.cause, String? message})
    : super(
        type: FailureType.authentication,
        message: message ?? AppErrorMessages.authentication,
      );
}

/// The account exists but is waiting for approval or was deactivated.
final class AccountInactiveFailure extends AppFailure {
  AccountInactiveFailure({super.cause, String? message})
    : super(
        type: FailureType.accountInactive,
        message: message ?? AppErrorMessages.accountInactive,
      );
}

/// The single entry point for translating third-party and platform errors to
/// failures the rest of the app can safely consume.
final class AppErrorHandler {
  const AppErrorHandler._();

  static Failure handle(Object error) {
    if (error is Failure) return error;

    // Check for FirebaseException first
    if (error is FirebaseException) {
      return fromFirebaseException(error);
    }

    // Workaround for potential type matching issues in some environments (like tests)
    final errorStr = error.toString();
    if (errorStr.contains('FirebaseException')) {
      try {
        final dynamic dynError = error;
        final String code = dynError.code as String;
        return fromFirebaseCode(code, cause: error);
      } catch (_) {}
    }

    if (error is DioException) return fromDio(error);
    if (error is SocketException || error is HttpException) {
      return NetworkFailure(cause: error);
    }
    if (error is TimeoutException) return RequestTimeoutFailure(cause: error);
    if (error is FormatException) return ResponseParsingFailure(cause: error);

    // Check for TypeError specifically to avoid accidental matches
    if (errorStr.contains('TypeError')) {
      return ResponseParsingFailure(cause: error);
    }

    return DefaultFailure(cause: error);
  }

  static Failure fromFirebaseException(FirebaseException error) {
    return fromFirebaseCode(error.code, cause: error);
  }

  static Failure fromFirebaseCode(String code, {Object? cause}) {
    return switch (code) {
      'permission-denied' => ForbiddenFailure(cause: cause),
      'not-found' => NotFoundFailure(cause: cause),
      'unavailable' => NetworkFailure(cause: cause),
      'deadline-exceeded' => RequestTimeoutFailure(cause: cause),
      'already-exists' => ConflictFailure(cause: cause),
      'unauthenticated' => UnauthorizedFailure(cause: cause),
      'resource-exhausted' => RateLimitFailure(cause: cause),
      'cancelled' => RequestCancelledFailure(cause: cause),
      'internal' || 'data-loss' => ServerFailure(cause: cause),
      _ => DefaultFailure(cause: cause),
    };
  }

  static Failure fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return RequestTimeoutFailure(cause: error);
      case DioExceptionType.cancel:
        return RequestCancelledFailure(cause: error);
      case DioExceptionType.connectionError:
        return NetworkFailure(cause: error);
      case DioExceptionType.badCertificate:
        return NetworkFailure(
          cause: error,
          message: 'A secure connection could not be established.',
        );
      case DioExceptionType.badResponse:
        return fromStatusCode(error.response?.statusCode, cause: error);
      case DioExceptionType.unknown:
        return handle(error.error ?? error);
    }
  }

  static Failure fromStatusCode(int? statusCode, {Object? cause}) {
    return switch (statusCode) {
      null || 0 => NetworkFailure(cause: cause),
      400 || 422 => ValidationFailure(cause: cause),
      401 => UnauthorizedFailure(cause: cause),
      403 => ForbiddenFailure(cause: cause),
      404 => NotFoundFailure(cause: cause),
      408 || 504 => RequestTimeoutFailure(cause: cause),
      409 => ConflictFailure(cause: cause),
      429 => RateLimitFailure(cause: cause),
      >= 500 && <= 599 => ServerFailure(cause: cause, statusCode: statusCode),
      _ => DefaultFailure(cause: cause),
    };
  }

  /// Accepts `FirebaseAuthException.code` without importing Firebase into core.
  static Failure fromFirebaseAuthCode(String code, {Object? cause}) {
    return switch (code) {
      'invalid-email' || 'weak-password' => ValidationFailure(cause: cause),
      'email-already-in-use' => ConflictFailure(
        cause: cause,
        message: 'An account already exists for this email address.',
      ),
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => AuthenticationFailure(
        cause: cause,
        message: 'Incorrect email or password.',
      ),
      'user-disabled' => AuthenticationFailure(
        cause: cause,
        message: 'This account has been disabled.',
      ),
      'requires-recent-login' => UnauthorizedFailure(
        cause: cause,
        message: 'Please sign in again to continue.',
      ),
      'too-many-requests' => RateLimitFailure(cause: cause),
      'network-request-failed' => NetworkFailure(cause: cause),
      'operation-not-allowed' => ForbiddenFailure(cause: cause),
      _ => AuthenticationFailure(cause: cause),
    };
  }
}

/// Backwards-compatible facade for existing auth data sources.
final class FirebaseAuthFailureMapper {
  const FirebaseAuthFailureMapper._();

  static Failure fromCode(String code, {Object? cause}) =>
      AppErrorHandler.fromFirebaseAuthCode(code, cause: cause);
}

abstract final class AppErrorMessages {
  static const unknown = 'Something went wrong. Please try again later.';
  static const network = 'No internet connection. Please check your network.';
  static const timeout = 'The request took too long. Please try again.';
  static const requestCancelled = 'The request was cancelled.';
  static const unauthorized = 'Your session has expired. Please sign in again.';
  static const forbidden = 'You do not have permission to perform this action.';
  static const notFound = 'The requested item could not be found.';
  static const conflict =
      'This item was changed elsewhere. Please refresh and try again.';
  static const validation = 'Please check the entered information.';
  static const rateLimit =
      'Too many requests. Please wait a moment and try again.';
  static const server = 'The server is unavailable. Please try again later.';
  static const cacheRead = 'Unable to load the saved data.';
  static const cacheWrite = 'Unable to save your changes locally.';
  static const responseParsing = 'The received data could not be read.';
  static const authentication = 'Authentication failed. Please try again.';
  static const accessRequested =
      'Request sent. You can sign in once an admin approves your account.';
  static const accountInactive =
      'Your account is not active yet. Ask a workspace admin to approve it.';
}
