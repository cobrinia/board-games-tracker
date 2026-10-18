import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Thin wrapper over Firebase Analytics.
///
/// firebase_analytics has no Windows/Linux implementation, and widget tests
/// run without Firebase at all. On those platforms the service is created
/// disabled and every method does nothing, so callers never need checks.
class AnalyticsService {
  AnalyticsService() : _analytics = isSupported ? FirebaseAnalytics.instance : null;

  /// No-op instance for tests and unsupported platforms.
  AnalyticsService.disabled() : _analytics = null;

  final FirebaseAnalytics? _analytics;

  static bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// Observer for the root navigator (one observer per navigator).
  late final NavigatorObserver rootObserver = createObserver();

  /// Logs a `screen_view` for every named route pushed on the navigator.
  NavigatorObserver createObserver() {
    final analytics = _analytics;
    return analytics == null
        ? NavigatorObserver()
        : FirebaseAnalyticsObserver(analytics: analytics);
  }

  /// Recommended `login` event; [method] is e.g. 'email' or 'google'.
  Future<void> logLogin(String method) =>
      _run((a) => a.logLogin(loginMethod: method));

  /// Recommended `sign_up` event.
  Future<void> logSignUp(String method) =>
      _run((a) => a.logSignUp(signUpMethod: method));

  /// Manual screen view, used for bottom-bar tabs (they are not routes).
  Future<void> logScreen(String name) =>
      _run((a) => a.logScreenView(screenName: name, screenClass: name));

  /// Custom event, e.g. `game_added` with `{'category': 'Strategy'}`.
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) =>
      _run((a) => a.logEvent(name: name, parameters: parameters));

  /// Ties events to the signed-in user (uid only, never the email).
  Future<void> setUserId(String? uid) => _run((a) => a.setUserId(id: uid));

  /// Analytics must never break the app: errors are only printed.
  Future<void> _run(Future<void> Function(FirebaseAnalytics) call) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await call(analytics);
    } catch (error) {
      debugPrint('Analytics error: $error');
    }
  }
}
