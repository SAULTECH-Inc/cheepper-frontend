import 'package:flutter_test/flutter_test.dart';
import 'package:cheepper_frontend/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CheepperApp());
    expect(find.byType(CheepperApp), findsOneWidget);
  });
}
