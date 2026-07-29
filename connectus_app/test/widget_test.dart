import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:connectus_app/features/authentication/presentation/login_screen.dart';
import 'package:connectus_app/features/authentication/presentation/welcome_screen.dart';

void main() {
  testWidgets('ConnectUs welcome screen displays correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('ConnectUs'), findsOneWidget);
    expect(find.text('Welcome to ConnectUs!'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });

  testWidgets('Password recovery dialog accepts an email address', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Send link'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      findsOneWidget,
    );
  });
}
