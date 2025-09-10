import 'package:flutter/foundation.dart';

/// Conditional logging utility that only logs in debug mode.
/// Eliminates performance overhead in release builds.
class AppLogger {
  static const bool _enableLogging = kDebugMode;
  
  /// Logs debug information only in debug builds.
  static void debug(String message, {String? tag}) {
    if (!_enableLogging) return;
    
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final prefix = tag != null ? '[$tag]' : '[DEBUG]';
    debugPrint('$timestamp $prefix $message');
  }
  
  /// Logs information messages only in debug builds.
  static void info(String message, {String? tag}) {
    if (!_enableLogging) return;
    
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final prefix = tag != null ? '[$tag]' : '[INFO]';
    debugPrint('$timestamp $prefix $message');
  }
  
  /// Logs warning messages only in debug builds.
  static void warn(String message, {String? tag}) {
    if (!_enableLogging) return;
    
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final prefix = tag != null ? '[$tag]' : '[WARN]';
    debugPrint('$timestamp $prefix $message');
  }
  
  /// Logs error messages only in debug builds.
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!_enableLogging) return;
    
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final prefix = tag != null ? '[$tag]' : '[ERROR]';
    
    debugPrint('$timestamp $prefix $message');
    if (error != null) {
      debugPrint('$timestamp $prefix Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('$timestamp $prefix StackTrace: $stackTrace');
    }
  }
  
  /// Logs authentication-related messages.
  static void auth(String message) {
    debug(message, tag: 'AUTH');
  }
  
  /// Logs FCM-related messages.
  static void fcm(String message) {
    debug(message, tag: 'FCM');
  }
  
  /// Logs chat-related messages.
  static void chat(String message) {
    debug(message, tag: 'CHAT');
  }
  
  /// Logs notification-related messages.
  static void notification(String message) {
    debug(message, tag: 'NOTIFICATION');
  }
  
  /// Logs database-related messages.
  static void database(String message) {
    debug(message, tag: 'DATABASE');
  }
}