import 'package:flutter_test/flutter_test.dart';
import 'package:connectus_app/app/connect_us_app.dart';

void main() {
  testWidgets(
    'ConnectUs welcome screen displays correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ConnectUsApp());

      expect(find.text('ConnectUs'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
    },
  );
}