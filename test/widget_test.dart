import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:board_games/core/widgets/app_bottom_nav.dart';
import 'package:board_games/features/home/home_screen.dart';
import 'package:board_games/main.dart';

void main() {
  testWidgets('Valid login opens the home screen', (WidgetTester tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MyApp());

    // Invalid input: validation errors, still on login.
    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Please enter a valid email address'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('Every tab opens without errors', (WidgetTester tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

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

  testWidgets('Google sign-in opens the app', (WidgetTester tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Sign in with Google'));
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  // Runs last: it deletes a player from the shared in-memory data.
  testWidgets('A player can be deleted and restored', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Sign in with Apple'));
    await tester.tap(find.text('Sign in with Apple'));
    await tester.pumpAndSettle();
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

/// Test screens default to 800x600; use a typical phone size instead.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}
