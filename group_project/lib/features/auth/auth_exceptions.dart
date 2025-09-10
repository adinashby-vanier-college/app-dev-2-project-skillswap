/// Custom exception classes for authentication errors.
abstract class AuthException implements Exception {
  final String message;
  final String? code;
  
  const AuthException(this.message, {this.code});
  
  @override
  String toString() => message;
}

/// Exception thrown when email/password authentication fails.
class AuthCredentialException extends AuthException {
  const AuthCredentialException(super.message, {super.code});
}

/// Exception thrown when user account is disabled or deleted.
class AuthUserException extends AuthException {
  const AuthUserException(super.message, {super.code});
}

/// Exception thrown when network connectivity issues occur.
class AuthNetworkException extends AuthException {
  const AuthNetworkException(super.message, {super.code});
}

/// Exception thrown when social authentication (Google, Twitter, etc.) fails.
class AuthSocialException extends AuthException {
  const AuthSocialException(super.message, {super.code});
}

/// Exception thrown when email verification is required.
class AuthEmailVerificationException extends AuthException {
  const AuthEmailVerificationException(super.message, {super.code});
}

/// Exception thrown for unknown authentication errors.
class AuthUnknownException extends AuthException {
  const AuthUnknownException(super.message, {super.code});
}

/// Utility class to convert Firebase exceptions to custom exceptions.
class AuthExceptionMapper {
  static AuthException mapFirebaseException(dynamic exception, String defaultMessage) {
    if (exception is! Exception) {
      return AuthUnknownException(defaultMessage);
    }
    
    final exceptionString = exception.toString().toLowerCase();
    
    // Network-related errors
    if (exceptionString.contains('network') || 
        exceptionString.contains('timeout') ||
        exceptionString.contains('connection')) {
      return const AuthNetworkException(
        'Network connection failed. Please check your internet connection.',
        code: 'network-error'
      );
    }
    
    // User credential errors
    if (exceptionString.contains('wrong-password') || 
        exceptionString.contains('invalid-credential')) {
      return const AuthCredentialException(
        'Invalid email or password. Please check your credentials.',
        code: 'invalid-credential'
      );
    }
    
    if (exceptionString.contains('user-not-found')) {
      return const AuthCredentialException(
        'No account found with this email address.',
        code: 'user-not-found'
      );
    }
    
    if (exceptionString.contains('email-already-in-use')) {
      return const AuthCredentialException(
        'An account already exists with this email address.',
        code: 'email-already-in-use'
      );
    }
    
    if (exceptionString.contains('weak-password')) {
      return const AuthCredentialException(
        'Password is too weak. Please use at least 6 characters.',
        code: 'weak-password'
      );
    }
    
    if (exceptionString.contains('invalid-email')) {
      return const AuthCredentialException(
        'Please enter a valid email address.',
        code: 'invalid-email'
      );
    }
    
    // User account errors
    if (exceptionString.contains('user-disabled')) {
      return const AuthUserException(
        'This account has been disabled. Please contact support.',
        code: 'user-disabled'
      );
    }
    
    if (exceptionString.contains('too-many-requests')) {
      return const AuthUserException(
        'Too many failed attempts. Please try again later.',
        code: 'too-many-requests'
      );
    }
    
    // Email verification
    if (exceptionString.contains('email-not-verified')) {
      return const AuthEmailVerificationException(
        'Please verify your email address before signing in.',
        code: 'email-not-verified'
      );
    }
    
    // Social auth errors
    if (exceptionString.contains('google') || 
        exceptionString.contains('twitter') ||
        exceptionString.contains('facebook') ||
        exceptionString.contains('popup') ||
        exceptionString.contains('cancelled')) {
      return const AuthSocialException(
        'Social sign-in was cancelled or failed. Please try again.',
        code: 'social-auth-failed'
      );
    }
    
    // Default to unknown error
    return AuthUnknownException(
      defaultMessage.isNotEmpty ? defaultMessage : 'An unexpected error occurred.',
      code: 'unknown-error'
    );
  }
}