import 'package:board_games/core/services/analytics_service.dart';
import 'package:board_games/core/widgets/app_bottom_nav.dart';
import 'package:board_games/features/auth/login_screen.dart';
import 'package:board_games/features/home/home_screen.dart';
import 'package:board_games/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';

void main() {
  testWidgets('Login validates the form and shows Firebase errors', (
    tester,
  ) async {
    await startApp(tester);

    // Local validation: nothing is sent to the repository.
    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    // Valid form, wrong password: readable error, still on login.
    await tester.enterText(find.byType(TextFormField).at(0), FakeAuthRepository.email);
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-pass1');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not sign in. Check your email and password.'),
      findsOneWidget,
    );
    expect(find.byType(LoginScreen), findsOneWidget);

    // Right password: the gate opens the app.
    await tester.enterText(
      find.byType(TextFormField).at(1),
      FakeAuthRepository.password,
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text('Test Player'), findsOneWidget);
  });

  testWidgets('Every tab opens without errors', (tester) async {
    await startApp(tester);
    await signInWithEmail(tester);

    const expectedText = {
      'Catalog': 'Search game library...',
      'Players': 'Search players...',
      'Profile': 'Settings',
      'Home': 'Recent Sessions',
    };
    for (final MapEntry(key: tab, value: text) in expectedText.entries) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget, reason: 'tab $tab');
    }
  });

  testWidgets('Registration validates every field and opens the app', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(2), 'password');
    await tester.enterText(fields.at(3), 'different1');
    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Use both letters and numbers'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.enterText(fields.at(0), 'New Player');
    await tester.enterText(fields.at(1), 'new@example.com');
    await tester.enterText(fields.at(2), 'board123');
    await tester.enterText(fields.at(3), 'board123');
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('New Player'), findsOneWidget);
  });

  testWidgets('Forgot password sends a link to the typed email', (tester) async {
    final auth = await startApp(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'me@example.com');
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(auth.lastResetEmail, 'me@example.com');
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Google sign-in opens the app, sign out returns to login', (
    tester,
  ) async {
    await startApp(tester);
    await tester.ensureVisible(find.text('Sign in with Google'));
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Google Player'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sign Out'), 300);
    // Scroll the whole button into view, not just its top edge.
    await tester.ensureVisible(find.text('Sign Out'));
    await tester.pumpAndSettle();
    // The "Signed in as ..." snack bar floats over the bottom of the screen
    // and would catch the tap; let it disappear (it lives 4 seconds).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign Out?'), findsOneWidget); // dialog is open
    await tester.tap(find.text('Sign Out').last); // confirm in the dialog
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Change password checks the current password', (tester) async {
    await startApp(tester);
    await signInWithEmail(tester);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'not-my-password');
    await tester.enterText(fields.at(1), 'newpass123');
    await tester.enterText(fields.at(2), 'newpass123');
    await tester.ensureVisible(find.text('Update Password'));
    await tester.tap(find.text('Update Password'));
    await tester.pumpAndSettle();
    expect(find.text('The current password is incorrect.'), findsOneWidget);

    await tester.enterText(fields.at(0), FakeAuthRepository.password);
    await tester.tap(find.text('Update Password'));
    await tester.pumpAndSettle();
    expect(find.text('Password updated'), findsOneWidget);
  });

  // Runs last: it deletes a player from the shared in-memory data.
  testWidgets('A player can be deleted and restored', (tester) async {
    await startApp(tester);
    await signInWithEmail(tester);
    await tester.tap(find.text('Players').last);
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete player').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete Player?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('John Doe'), findsNothing);

    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(find.text('John Doe'), findsOneWidget);
  });
}

/// Starts the app with a fake repository and waits for the login screen.
Future<FakeAuthRepository> startApp(WidgetTester tester) async {
  usePhoneScreen(tester);
  final auth = FakeAuthRepository();
  await tester.pumpWidget(
    MyApp(authRepository: auth, analytics: AnalyticsService.disabled()),
  );
  await tester.pumpAndSettle();
  return auth;
}

Future<void> signInWithEmail(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).at(0),
    FakeAuthRepository.email,
  );
  await tester.enterText(
    find.byType(TextFormField).at(1),
    FakeAuthRepository.password,
  );
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
}

/// Test screens default to 800x600; use a typical phone size instead.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}
