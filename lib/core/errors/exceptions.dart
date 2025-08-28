class ApiException implements Exception {
  final int code;
  final String message;
  final String type;

  ApiException({required this.code, required this.message, required this.type});

  @override
  String toString() => 'ApiException: [$code] $message (Type: $type)';
}

class ValidationException extends ApiException {
  ValidationException(String message)
    : super(code: 400, message: message, type: 'ValidationError');
}

class AuthenticationException extends ApiException {
  AuthenticationException(String message)
    : super(code: 401, message: message, type: 'AuthenticationError');
}

class AuthorizationException extends ApiException {
  AuthorizationException(String message)
    : super(code: 403, message: message, type: 'AuthorizationError');
}

class NotFoundException extends ApiException {
  NotFoundException(String message)
    : super(code: 404, message: message, type: 'NotFoundError');
}

class ConflictException extends ApiException {
  ConflictException(String message)
    : super(code: 409, message: message, type: 'ConflictError');
}

class ServerException extends ApiException {
  ServerException([String? message])
    : super(
        code: 500,
        message: message ?? 'Internal server error',
        type: 'ServerError',
      );
}

class NetworkException extends ApiException {
  NetworkException([String? message])
    : super(
        code: 503,
        message: message ?? 'Network error',
        type: 'NetworkError',
      );
}
