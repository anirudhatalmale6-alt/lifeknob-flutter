import 'package:flutter_test/flutter_test.dart';

import 'package:lifeknob/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LifeKnobApp());

    // Verify the splash screen shows LifeKnob branding
    expect(find.text('LifeKnob'), findsOneWidget);
  });
}
