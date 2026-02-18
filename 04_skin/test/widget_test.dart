// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kithly_app/main.dart';

void main() {
  testWidgets('App loads successfully smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KithLyApp());
    // Use pump instead of pumpAndSettle because ShopPortal has infinite animations/timers
    await tester.pump(const Duration(seconds: 2));

    // Verify that the ShopPortal loads (look for 'Command Center' text)
    expect(find.text('Command Center'), findsOneWidget);
  });
}
