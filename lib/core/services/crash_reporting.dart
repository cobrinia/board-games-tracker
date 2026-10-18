import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crash and error reporting through Firebase Crashlytics.
///
/// Crashlytics works on Android, iOS and macOS only. Elsewhere (web,
/// Windows, tests) [init] is skipped and errors are just printed.
class CrashReporting {
  CrashReporting._();

  static bool _enabled = false;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static bool get isEnabled => _enabled;

  /// Call once in main(), right after Firebase.initializeApp().
  static Future<void> init() async {
    if (!isSupported) return;
    _enabled = true;
    final crashlytics = FirebaseCrashlytics.instance;
    // Keep reports in debug builds too, so the lab test crash is visible.
    await crashlytics.setCrashlyticsCollectionEnabled(true);

    // Errors caught by the Flutter framework (build, layout, paint...).
    FlutterError.onError = crashlytics.recordFlutterFatalError;

    // Uncaught async errors that the framework does not see.
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Reports an error the app handled and survived.
  static Future<void> recordNonFatal(
    Object error,
    StackTrace stack, {
    String? reason,
  }) async {
    if (!_enabled) {
      debugPrint('Non-fatal error ($reason): $error');
      return;
    }
    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: reason,
      fatal: false,
    );
  }

  /// Breadcrumb attached to the next report. Never log passwords or tokens.
  static Future<void> log(String message) async {
    if (_enabled) await FirebaseCrashlytics.instance.log(message);
  }

  /// Links reports to the signed-in user's uid ('' clears it).
  static Future<void> setUser(String? uid) async {
    if (_enabled) await FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '');
  }

  /// Settings → Developer → "Send test error": a handled (non-fatal) error.
  static Future<void> sendTestNonFatal() async {
    try {
      throw StateError('Test non-fatal error from the Settings screen');
    } catch (error, stack) {
      await log('User tapped "Send test error"');
      await recordNonFatal(error, stack, reason: 'Crashlytics integration test');
    }
  }

  /// Settings → Developer → "Force test crash": closes the app on purpose.
  /// The report is uploaded the next time the app starts.
  static void forceTestCrash() {
    if (!_enabled) {
      throw UnsupportedError('Crashlytics is not available on this platform.');
    }
    FirebaseCrashlytics.instance.crash();
  }
}
