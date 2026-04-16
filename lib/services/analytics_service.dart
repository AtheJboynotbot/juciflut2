import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Centralized analytics and crashlytics service
/// 
/// Tracks user events, sets user properties, and reports crashes
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  // Crashlytics is not supported on Flutter Web — returns null on web
  static FirebaseCrashlytics? get _crashlytics =>
      kIsWeb ? null : FirebaseCrashlytics.instance;

  // Get analytics observer for navigation tracking
  static FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(
        analytics: _analytics,
      );

  // ---------------------------------------------------------------------------
  //  INITIALIZATION
  // ---------------------------------------------------------------------------

  /// Initialize analytics and crashlytics
  static Future<void> initialize() async {
    try {
      // Enable analytics collection
      await _analytics.setAnalyticsCollectionEnabled(true);
      
      // Enable crashlytics collection (mobile only)
      await _crashlytics?.setCrashlyticsCollectionEnabled(true);
      
      AppLogger.info('[Analytics] Initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Initialization failed', e, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  //  USER PROPERTIES
  // ---------------------------------------------------------------------------

  /// Set user ID (faculty ID)
  static Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      await _crashlytics?.setUserIdentifier(userId);
      AppLogger.debug('[Analytics] User ID set: $userId');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to set user ID', e, stackTrace);
    }
  }

  /// Set user properties
  static Future<void> setUserProperties({
    String? department,
    String? role,
    String? email,
  }) async {
    try {
      if (department != null) {
        await _analytics.setUserProperty(name: 'department', value: department);
      }
      if (role != null) {
        await _analytics.setUserProperty(name: 'role', value: role);
      }
      if (email != null) {
        await _analytics.setUserProperty(name: 'email', value: email);
      }
      AppLogger.debug('[Analytics] User properties set');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to set user properties', e, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  //  AUTHENTICATION EVENTS
  // ---------------------------------------------------------------------------

  /// Track successful login
  static Future<void> logLoginSuccess({
    required String method,
    String? email,
  }) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      await _logCustomEvent(
        'login_success',
        parameters: {
          'method': method,
          if (email != null) 'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      AppLogger.info('[Analytics] Login success tracked: $method');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log login', e, stackTrace);
    }
  }

  /// Track logout
  static Future<void> logLogout() async {
    try {
      await _logCustomEvent('logout', parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      });
      AppLogger.info('[Analytics] Logout tracked');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log logout', e, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  //  SCHEDULE EVENTS
  // ---------------------------------------------------------------------------

  /// Track schedule creation
  static Future<void> logScheduleCreated({
    required String scheduleType,
    required String day,
    required String duration,
  }) async {
    try {
      await _logCustomEvent(
        'schedule_created',
        parameters: {
          'type': scheduleType,
          'day': day,
          'duration': duration,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      AppLogger.info('[Analytics] Schedule created: $scheduleType on $day');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log schedule creation', e, stackTrace);
    }
  }

  /// Track schedule update
  static Future<void> logScheduleUpdated({
    required String scheduleType,
    required String day,
  }) async {
    try {
      await _logCustomEvent(
        'schedule_updated',
        parameters: {
          'type': scheduleType,
          'day': day,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      AppLogger.info('[Analytics] Schedule updated: $scheduleType on $day');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log schedule update', e, stackTrace);
    }
  }

  /// Track schedule deletion
  static Future<void> logScheduleDeleted({
    required String scheduleType,
    required String day,
  }) async {
    try {
      await _logCustomEvent(
        'schedule_deleted',
        parameters: {
          'type': scheduleType,
          'day': day,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      AppLogger.info('[Analytics] Schedule deleted: $scheduleType on $day');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log schedule deletion', e, stackTrace);
    }
  }

  /// Track schedule conflict detection
  static Future<void> logScheduleConflict({
    required String day,
    required String timeRange,
  }) async {
    try {
      await _logCustomEvent(
        'schedule_conflict',
        parameters: {
          'day': day,
          'time_range': timeRange,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      AppLogger.warning('[Analytics] Schedule conflict: $day $timeRange');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log conflict', e, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  //  PROFILE EVENTS
  // ---------------------------------------------------------------------------

  /// Track profile update
  static Future<void> logProfileUpdated({
    required List<String> fieldsUpdated,
  }) async {
    try {
      await _logCustomEvent(
        'profile_updated',
        parameters: {
          'fields': fieldsUpdated.join(','),
          'field_count': fieldsUpdated.length,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      AppLogger.info('[Analytics] Profile updated: ${fieldsUpdated.join(", ")}');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log profile update', e, stackTrace);
    }
  }

  /// Track profile image upload
  static Future<void> logProfileImageUploaded({
    required int fileSize,
  }) async {
    try {
      await _logCustomEvent(
        'profile_image_uploaded',
        parameters: {
          'file_size_kb': (fileSize / 1024).round(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      AppLogger.info('[Analytics] Profile image uploaded');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log image upload', e, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  //  BOOKING EVENTS
  // ---------------------------------------------------------------------------

  /// Track booking request
  static Future<void> logBookingRequested({
    required String scheduleType,
    required String day,
    required String timeSlot,
  }) async {
    try {
      await _logCustomEvent(
        'booking_requested',
        parameters: {
          'type': scheduleType,
          'day': day,
          'time_slot': timeSlot,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      AppLogger.info('[Analytics] Booking requested: $scheduleType on $day');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log booking', e, stackTrace);
    }
  }

  /// Track booking confirmed
  static Future<void> logBookingConfirmed({
    required String bookingId,
  }) async {
    try {
      await _logCustomEvent(
        'booking_confirmed',
        parameters: {
          'booking_id': bookingId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      AppLogger.info('[Analytics] Booking confirmed: $bookingId');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log booking confirmation', e, stackTrace);
    }
  }

  /// Track booking cancelled
  static Future<void> logBookingCancelled({
    required String bookingId,
    required String reason,
  }) async {
    try {
      await _logCustomEvent(
        'booking_cancelled',
        parameters: {
          'booking_id': bookingId,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      AppLogger.info('[Analytics] Booking cancelled: $bookingId');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log booking cancellation', e, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  //  UI EVENTS
  // ---------------------------------------------------------------------------

  /// Track screen view
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      AppLogger.debug('[Analytics] Screen view: $screenName');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log screen view', e, stackTrace);
    }
  }

  /// Track button/action clicks
  static Future<void> logButtonClick({
    required String buttonName,
    String? screenName,
  }) async {
    try {
      await _logCustomEvent(
        'button_click',
        parameters: {
          'button_name': buttonName,
          if (screenName != null) 'screen_name': screenName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      AppLogger.debug('[Analytics] Button click: $buttonName');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log button click', e, stackTrace);
    }
  }

  /// Track search
  static Future<void> logSearch({
    required String searchTerm,
    String? searchCategory,
  }) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
        parameters: {
          if (searchCategory != null) 'category': searchCategory,
        },
      );
      AppLogger.debug('[Analytics] Search: $searchTerm');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log search', e, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  //  ERROR & CRASH REPORTING
  // ---------------------------------------------------------------------------

  /// Record a non-fatal error
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics?.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
      AppLogger.error(
        '[Crashlytics] Error recorded${fatal ? ' (FATAL)' : ''}',
        exception,
        stackTrace,
      );
    } catch (e, stackTrace) {
      AppLogger.error('[Crashlytics] Failed to record error', e, stackTrace);
    }
  }

  /// Log a message to Crashlytics
  static void log(String message) {
    try {
      _crashlytics?.log(message);
      AppLogger.debug('[Crashlytics] Logged: $message');
    } catch (e, stackTrace) {
      AppLogger.error('[Crashlytics] Failed to log message', e, stackTrace);
    }
  }

  /// Set custom key-value pairs for crash reports
  static Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics?.setCustomKey(key, value);
      AppLogger.debug('[Crashlytics] Custom key set: $key = $value');
    } catch (e, stackTrace) {
      AppLogger.error('[Crashlytics] Failed to set custom key', e, stackTrace);
    }
  }

  /// Force a test crash (dev mode only)
  static void testCrash() {
    AppLogger.warning('[Crashlytics] TEST CRASH TRIGGERED');
    _crashlytics?.crash();
  }

  // ---------------------------------------------------------------------------
  //  HELPER METHODS
  // ---------------------------------------------------------------------------

  /// Log custom event with parameters
  static Future<void> _logCustomEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters,
    );
  }

  /// Track app open
  static Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
      AppLogger.info('[Analytics] App opened');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log app open', e, stackTrace);
    }
  }

  /// Track tutorial begin
  static Future<void> logTutorialBegin() async {
    try {
      await _analytics.logTutorialBegin();
      AppLogger.info('[Analytics] Tutorial begun');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log tutorial', e, stackTrace);
    }
  }

  /// Track tutorial complete
  static Future<void> logTutorialComplete() async {
    try {
      await _analytics.logTutorialComplete();
      AppLogger.info('[Analytics] Tutorial completed');
    } catch (e, stackTrace) {
      AppLogger.error('[Analytics] Failed to log tutorial completion', e, stackTrace);
    }
  }
}
