// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';

import 'package:signapp/main.dart';

final CameraDescription? testCamera = null;

void main() {
  group('MyApp widget tests', () {
    testWidgets('Counter increments smoke test', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(MyApp(camera: testCamera));

      // Verify that our counter starts at 0.
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);

      // Tap the '+' icon and trigger a frame.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Verify that our counter has incremented.
      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('FAB exists and increments twice', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(camera: testCamera));

      // Verify FloatingActionButton is present.
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Tap twice and verify counter shows 2.
      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('App is wrapped in a MaterialApp', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(camera: testCamera));

      // Ensure the top-level MaterialApp (or WidgetsApp) is present.
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}

