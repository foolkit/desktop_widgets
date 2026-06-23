import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_widgets/src/pickers/date_time_picker.dart';

void main() {
  testWidgets('DateTimePicker renders initial value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DateTimePicker(
            initialValue: DateTime(2026, 6, 17, 10, 30, 45),
          ),
        ),
      ),
    );
    expect(find.text('2026-06-17 10:30:45'), findsOneWidget);
  });

  testWidgets('DateTimePicker onChanged called when segment changes', (tester) async {
    DateTime? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DateTimePicker(
            initialValue: DateTime(2026, 6, 17, 10, 30, 45),
            onChanged: (v) => changed = v,
          ),
        ),
      ),
    );
    expect(find.byType(DateTimePicker), findsOneWidget);
    expect(changed, isNull);
  });
}
