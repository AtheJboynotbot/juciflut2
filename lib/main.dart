//Albert John A. Judaya
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'providers/faculty_provider.dart';
import 'providers/booking_provider.dart';
import 'services/analytics_service.dart';
import 'utils/logger.dart';
import 'views/web_login_screen.dart';
import 'views/dashboard_shell.dart';
import 'views/pages/schedule_details_screen.dart';

/// Main entry point - loads environment variables and initializes Firebase
void main() async {
  // Run app in error zone to catch all errors
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Load environment variables from .env file
    // To use different environments, change the fileName parameter:
    // - .env.dev (development)
    // - .env.staging (staging)
    // - .env.prod (production)
    await dotenv.load(fileName: ".env");
    
    AppLogger.info('🌍 Environment: ${DefaultFirebaseOptions.environment}');
    AppLogger.info('🔧 Debug logging: ${DefaultFirebaseOptions.isDebugLoggingEnabled}');

    // Initialize Firebase with environment-specific configuration
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Initialize Analytics and Crashlytics
    await AnalyticsService.initialize();
    
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    // Crashlytics is not supported on Flutter Web — guard with !kIsWeb
    FlutterError.onError = (errorDetails) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      }
      AppLogger.fatal('Flutter Fatal Error', errorDetails.exception, errorDetails.stack);
    };
    
    // Pass all uncaught asynchronous errors that aren't handled by Flutter to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      AppLogger.fatal('Platform Error', error, stack);
      return true;
    };

    // Ensure Firestore uses the server for reads (not stale cache)
    // Configure for the facconsult-firebase database
    final databaseId = dotenv.env['FIREBASE_DATABASE_ID'] ?? 'facconsult-firebase';
    final firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: databaseId,
    );
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    AppLogger.info('📊 Firestore database: $databaseId');
    
    // Track app open
    await AnalyticsService.logAppOpen();

    runApp(const JuCiApp());
  }, (error, stackTrace) {
    // Catch errors not caught by Flutter
    // Crashlytics is not supported on Flutter Web — guard with !kIsWeb
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    }
    AppLogger.fatal('Unhandled Error', error, stackTrace);
  });
}

class JuCiApp extends StatelessWidget {
  const JuCiApp({super.key});

  static const Color _kVioletAccent = Color(0xFF7C4DFF);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FacultyProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'JuCi University – Faculty Portal',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [
          AnalyticsService.observer, // Track screen navigation
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _kVioletAccent,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (_) => const WebLoginScreen(),
          '/dashboard': (_) => const DashboardShell(),
          '/schedule-details': (_) => const ScheduleDetailsScreen(),
        },
      ),
    );
  }
}
