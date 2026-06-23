import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_widgets/src/pickers/calendar_view.dart';

void main() {
  testWidgets('CalendarView displays month and year', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarView(
            selectedDate: DateTime(2026, 6, 17),
            onDateSelected: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('2026年6月'), findsOneWidget);
  });

  testWidgets('CalendarView selects date on tap', (tester) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarView(
            selectedDate: DateTime(2026, 6, 17),
            onDateSelected: (d) => selected = d,
          ),
        ),
      ),
    );
    await tester.tap(find.text('15'));
    await tester.pump();
    expect(selected, DateTime(2026, 6, 15));
  });
}
