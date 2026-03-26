/// Custom Exception Classes for Error Handling

/// Base exception for all data layer errors
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);
}

/// Network/connectivity errors
class NetworkException extends AppException {
  NetworkException(String message) : super(message);
  
  factory NetworkException.from(Object exception) {
    if (exception.toString().contains('SocketException')) {
      return NetworkException('No internet connection');
    } else if (exception.toString().contains('TimeoutException')) {
      return NetworkException('Request timed out');
    }
    return NetworkException('Network error occurred: ${exception.toString()}');
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
      return DataException('Server error', statusCode: 500);
    }
    return DataException('Data operation failed: ${exception.toString()}');
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
