import 'package:flutter/widgets.dart';

import 'auth/auth_repository.dart';
import 'services/analytics_service.dart';

/// Gives every screen access to the app-wide services without globals.
///
/// Created once in [MyApp]; tests pass a fake [AuthRepository] here.
/// Usage: `AppScope.of(context).auth.signOut()`.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.auth,
    required this.analytics,
    required super.child,
  });

  final AuthRepository auth;
  final AnalyticsService analytics;

  /// The services never change at runtime, so this lookup does not make the
  /// caller rebuild and is safe in callbacks like onPressed.
  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      auth != oldWidget.auth || analytics != oldWidget.analytics;
}
