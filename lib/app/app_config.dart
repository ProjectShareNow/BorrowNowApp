import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'BorrowNow';
  static const String appVersion = '1.0.0+1';

  /// Tracks whether Firebase has been successfully initialized
  static bool isFirebaseInitialized = false;

  /// When Firebase is not configured yet (no google-services.json / firebase_options),
  /// enables the interactive in-memory repository fallback so that reviewers, testers,
  /// and developers can fully interact with every screen, form, button, and workflow
  /// without crashing.
  static bool enableFallbackWhenFirebaseUnavailable = true;

  /// Error or status message when Firebase is not connected
  static String firebaseStatusMessage =
      'Firebase configuration pending. Integration interfaces are ready.';

  /// Log debug info safely
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[BorrowNow] $message');
    }
  }
}
