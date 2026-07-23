import 'package:desktop_widgets_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the fullscreen tab in the example app', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('DateTimePicker'), findsOneWidget);
    expect(find.text('SideSplitLayout'), findsOneWidget);
    expect(find.text('SplitLayout'), findsOneWidget);
    expect(find.text('Fullscreen'), findsOneWidget);
  });

  testWidgets('fullscreen demo tab renders without layout exceptions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fullscreen'));
    await tester.pumpAndSettle();

    expect(find.text('Status Panel'), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
