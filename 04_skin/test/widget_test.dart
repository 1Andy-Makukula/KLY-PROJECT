import 'package:flutter_test/flutter_test.dart';

import 'package:kithly_skin/main.dart';

void main() {
  testWidgets('Playground smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KithLyApp());

    // Verify that our Playground renders key elements
    expect(find.text('CONFIRM GIFT'), findsOneWidget);
    expect(find.text('CANCEL ORDER'), findsOneWidget);
    expect(find.text('Go Back'), findsOneWidget);
  });
}
