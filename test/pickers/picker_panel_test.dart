import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_widgets/src/pickers/picker_panel.dart';
import 'package:desktop_widgets/src/pickers/time_selector.dart';

void main() {
  testWidgets('PickerPanel displays calendar and time selector', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DateTimePickerPanel(
            value: DateTime(2026, 6, 17, 10, 30, 45),
            onChanged: (_) {},
            showSeconds: true,
            firstDayOfWeekIsMonday: true,
          ),
        ),
      ),
    );
    expect(find.text('2026年6月'), findsOneWidget);
    final timeSelector = find.byType(TimeSelector);
    expect(find.descendant(of: timeSelector, matching: find.text('10')), findsOneWidget);
    expect(find.descendant(of: timeSelector, matching: find.text('30')), findsOneWidget);
    expect(find.descendant(of: timeSelector, matching: find.text('45')), findsOneWidget);
  });
}
