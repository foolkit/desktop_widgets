import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_widgets/src/pickers/date_time_picker.dart';

void main() {
  testWidgets('DateTimePicker opens and closes panel via suffix icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DateTimePicker(
              initialValue: DateTime(2026, 6, 17, 10, 30, 45),
            ),
          ),
        ),
      ),
    );

    // Panel should not be visible initially.
    expect(find.text('2026年6月'), findsNothing);

    // Tap the suffix icon (dropdown arrow) to open the panel.
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    // Panel should now be visible.
    expect(find.text('2026年6月'), findsOneWidget);

    // Tap the suffix icon again to close the panel.
    await tester.tap(find.byIcon(Icons.arrow_drop_up));
    await tester.pumpAndSettle();

    // Panel should be gone.
    expect(find.text('2026年6月'), findsNothing);
  });

  testWidgets('DateTimePicker selects a date from the panel', (tester) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DateTimePicker(
              initialValue: DateTime(2026, 6, 17, 10, 30, 45),
              onChanged: (v) => selected = v,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    // Tap day 20 in the calendar.
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.day, 20);
    expect(selected!.month, 6);
    expect(selected!.year, 2026);
  });

  testWidgets('DateTimePicker closes panel when tapping outside', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.white)),
              Center(
                child: DateTimePicker(
                  initialValue: DateTime(2026, 6, 17, 10, 30, 45),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    expect(find.text('2026年6月'), findsOneWidget);

    // Tap outside the panel.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('2026年6月'), findsNothing);
  });
}
