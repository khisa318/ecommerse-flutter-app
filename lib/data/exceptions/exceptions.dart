import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Custom Exception Classes for Error Handling

/// Base exception for all data layer errors
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

/// Network/connectivity errors
class NetworkException extends AppException {
  NetworkException(String message) : super(message);

  factory NetworkException.unavailable() {
    return NetworkException('Unable to connect. Please check your internet.');
  }

  factory NetworkException.timedOut() {
    return NetworkException('The connection timed out. Please try again.');
  }
  
  factory NetworkException.from(Object exception) {
    if (UiSafeErrorMapper.isNetworkError(exception)) {
      return NetworkException.unavailable();
    } else if (exception is TimeoutException ||
        exception.toString().contains('TimeoutException')) {
      return NetworkException.timedOut();
    }
    return NetworkException.unavailable();
  }
}

/// Authentication and authorization errors
class AuthException extends AppException {
  AuthException(String message) : super(message);
  
  factory AuthException.unauthorized() {
    return AuthException('Unauthorized: Please login again');
  }
  
  factory AuthException.forbidden() {
    return AuthException('Forbidden: You don\'t have permission');
  }
  
  factory AuthException.sessionExpired() {
    return AuthException('Session expired: Please login again');
  }
}

/// Supabase API errors
class DataException extends AppException {
  final int? statusCode;
  
  DataException(
    String message, {
    this.statusCode,
  }) : super(message);
  
  factory DataException.from(Object exception) {
    if (exception.toString().contains('404')) {
      return DataException('Resource not found', statusCode: 404);
    } else if (exception.toString().contains('400')) {
      return DataException('Invalid request', statusCode: 400);
    } else if (exception.toString().contains('500')) {
      return DataException('Server error. Please try again later.', statusCode: 500);
    }
    return DataException('Something went wrong while loading data.');
  }
}

/// Validation errors (input validation failed)
class ValidationException extends AppException {
  final Map<String, String>? errors;
  
  ValidationException(
    String message, {
    this.errors,
  }) : super(message);
  
  factory ValidationException.invalidEmail() {
    return ValidationException('Invalid email address');
  }
  
  factory ValidationException.weakPassword() {
    return ValidationException('Password is too weak');
  }
  
  factory ValidationException.emptyFields() {
    return ValidationException('Please fill all required fields');
  }
}

/// Cache-related errors
class CacheException extends AppException {
  CacheException(String message) : super(message);
}

/// Entity not found errors
class EntityNotFoundException extends AppException {
  EntityNotFoundException(String entityType, dynamic id)
      : super('$entityType with id $id not found');
}

/// Business logic errors
class BusinessException extends AppException {
  BusinessException(String message) : super(message);
  
  factory BusinessException.insufficientStock(int requested, int available) {
    return BusinessException(
      'Insufficient stock: Requested $requested but only $available available',
    );
  }
  
  factory BusinessException.invalidOrderStatus(String currentStatus, String attemptedStatus) {
    return BusinessException(
      'Cannot change order status from $currentStatus to $attemptedStatus',
    );
  }
}

class UiSafeErrorMapper {
  static bool isNetworkError(Object error) {
    final text = error.toString().toLowerCase();
    return error is SocketException ||
        error is sb.AuthRetryableFetchException ||
        text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('network is unreachable') ||
        text.contains('connection reset by peer') ||
        text.contains('connection closed') ||
        text.contains('errno = 101') ||
        text.contains('errno = 111');
  }

  static AppException toAppException(
    Object error, {
    String? fallbackMessage,
  }) {
    if (error is AppException) {
      return error;
    }

    if (error is TimeoutException) {
      return NetworkException.timedOut();
    }

    if (isNetworkError(error)) {
      return NetworkException.unavailable();
    }

    if (error is sb.PostgrestException) {
      if (error.code == 'PGRST116') {
        return DataException('The requested record was not found.', statusCode: 404);
      }
      return DataException('Unable to load data right now.');
    }

    if (error is sb.StorageException || error is sb.FunctionException) {
      return DataException('Service temporarily unavailable. Please try again.');
    }

    if (error is sb.AuthException) {
      return AuthException.sessionExpired();
    }

    return DataException(fallbackMessage ?? 'Something went wrong. Please try again.');
  }

  static void logTechnicalError(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    developer.log(
      '[$operation] $error',
      name: 'cyberspex.data',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
