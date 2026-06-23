import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_widgets/src/pickers/time_selector.dart';

void main() {
  testWidgets('TimeSelector displays hour and minute', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimeSelector(
            hour: 10,
            minute: 30,
            second: 45,
            onHourChanged: (_) {},
            onMinuteChanged: (_) {},
            onSecondChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('10'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
  });

  testWidgets('TimeSelector hides seconds when showSeconds is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimeSelector(
            hour: 10,
            minute: 30,
            second: 45,
            onHourChanged: (_) {},
            onMinuteChanged: (_) {},
            onSecondChanged: (_) {},
            showSeconds: false,
          ),
        ),
      ),
    );
    expect(find.text('45'), findsNothing);
  });
}
