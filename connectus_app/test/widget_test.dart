import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:connectus_app/features/authentication/presentation/welcome_screen.dart';

void main() {
  testWidgets('ConnectUs welcome screen displays correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('ConnectUs'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });
}
