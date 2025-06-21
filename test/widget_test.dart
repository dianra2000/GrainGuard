import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grainguard/main.dart';
import 'package:grainguard/auth/login_screen.dart';
import 'package:grainguard/auth/register_screen.dart';

void main() {
  group('Authentication Screens Tests', () {
    testWidgets('Login Screen renders correctly', (WidgetTester tester) async {
      // Build our LoginScreen
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Verify the welcome text is present
      expect(find.text('# WELCOME!!'), findsOneWidget);

      // Verify the username/email field is present
      expect(find.text('Username / Email'), findsOneWidget);

      // Verify the password field is present
      expect(find.text('Password'), findsOneWidget);

      // Verify the login button is present
      expect(find.text('Login'), findsOneWidget);

      // Verify the register navigation is present
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('Register Screen renders correctly', (WidgetTester tester) async {
      // Build our RegisterScreen
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

      // Verify the register text is present
      expect(find.text('# REGISTER'), findsOneWidget);

      // Verify the username/email field is present
      expect(find.text('Username / Email'), findsOneWidget);

      // Verify the password field is present
      expect(find.text('Password'), findsOneWidget);

      // Verify the sign up button is present
      expect(find.text('Sign Up'), findsOneWidget);

      // Verify the login navigation is present
      expect(find.text("Already a member?"), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('Navigation between login and register screens',
        (WidgetTester tester) async {
      // Build our app starting with LoginScreen
      await tester.pumpWidget(const MyApp());

      // Verify we're on the login screen
      expect(find.text('# WELCOME!!'), findsOneWidget);

      // Tap the register button
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Verify we're now on the register screen
      expect(find.text('# REGISTER'), findsOneWidget);

      // Tap the sign in button
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      // Verify we're back on the login screen
      expect(find.text('# WELCOME!!'), findsOneWidget);
    });

    testWidgets('Text input works correctly', (WidgetTester tester) async {
      // Build our LoginScreen
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Enter text in username field
      await tester.enterText(
          find.byKey(const Key('usernameField')), 'testuser');
      expect(find.text('testuser'), findsOneWidget);

      // Enter text in password field
      await tester.enterText(
          find.byKey(const Key('passwordField')), 'password123');
      expect(find.text('password123'), findsNothing); // Because it's obscured
    });
  });
}