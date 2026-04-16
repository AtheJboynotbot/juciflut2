import 'package:logger/logger.dart';

/// Global logger instance for the application
/// 
/// Usage:
/// ```dart
/// AppLogger.debug('Debug message');
/// AppLogger.info('Info message');
/// AppLogger.warning('Warning message');
/// AppLogger.error('Error message', error, stackTrace);
/// ```
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  /// Log debug message
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal/critical error
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// Specific logger for Firebase operations
class FirebaseLogger {
  static void addSchedule(String message, [dynamic data]) {
    AppLogger.info('[Firebase.addSchedule] $message', data);
  }

  static void updateSchedule(String message, [dynamic data]) {
    AppLogger.info('[Firebase.updateSchedule] $message', data);
  }

  static void deleteSchedule(String message, [dynamic data]) {
    AppLogger.info('[Firebase.deleteSchedule] $message', data);
  }

  static void auth(String message, [dynamic data]) {
    AppLogger.info('[Firebase.auth] $message', data);
  }

  static void error(String message, dynamic error, [StackTrace? stackTrace]) {
    AppLogger.error('[Firebase.error] $message', error, stackTrace);
  }
}

/// Specific logger for validation operations
class ValidationLogger {
  static void success(String field, String message) {
    AppLogger.debug('[Validation.success] $field: $message');
  }

  static void failure(String field, String message) {
    AppLogger.warning('[Validation.failure] $field: $message');
  }
}

/// Specific logger for UI operations
class UILogger {
  static void navigation(String route) {
    AppLogger.debug('[UI.navigation] Navigating to: $route');
  }

  static void dialog(String action, String dialogName) {
    AppLogger.debug('[UI.dialog] $action: $dialogName');
  }

  static void error(String message, [dynamic error]) {
    AppLogger.error('[UI.error] $message', error);
  }
}
