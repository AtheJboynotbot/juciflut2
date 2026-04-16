// Firebase configuration using environment variables
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase options configured via environment variables (.env files)
///
/// Environment variables are loaded from:
/// - .env (default development)
/// - .env.dev (development)
/// - .env.staging (staging)
/// - .env.prod (production)
///
/// Example usage:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  /// Get the current platform's Firebase configuration
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Firebase options for Web platform
  static FirebaseOptions get web => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_WEB']!,
        appId: dotenv.env['FIREBASE_APP_ID_WEB']!,
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
      );

  /// Firebase options for Android platform
  static FirebaseOptions get android => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID']!,
        appId: dotenv.env['FIREBASE_APP_ID_ANDROID']!,
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      );

  /// Firebase options for iOS platform
  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_IOS']!,
        appId: dotenv.env['FIREBASE_APP_ID_IOS']!,
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
        androidClientId: dotenv.env['FIREBASE_ANDROID_CLIENT_ID'],
        iosClientId: dotenv.env['FIREBASE_IOS_CLIENT_ID'],
        iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID']!,
      );

  /// Firebase options for macOS platform
  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_IOS']!,
        appId: dotenv.env['FIREBASE_APP_ID_IOS']!,
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
        androidClientId: dotenv.env['FIREBASE_ANDROID_CLIENT_ID'],
        iosClientId: dotenv.env['FIREBASE_IOS_CLIENT_ID'],
        iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID']!,
      );

  /// Firebase options for Windows platform
  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_WINDOWS']!,
        appId: dotenv.env['FIREBASE_APP_ID_WINDOWS']!,
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
      );

  /// Get current environment name
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'dev';

  /// Check if running in development
  static bool get isDev => environment == 'dev';

  /// Check if running in staging
  static bool get isStaging => environment == 'staging';

  /// Check if running in production
  static bool get isProd => environment == 'prod';

  /// Check if debug logging is enabled
  static bool get isDebugLoggingEnabled =>
      dotenv.env['ENABLE_DEBUG_LOGGING']?.toLowerCase() == 'true';
}
