import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_widgets/src/pickers/input_field.dart';
import 'package:desktop_widgets/src/pickers/date_time_format.dart';

void main() {
  testWidgets('InputSegment displays value with padding', (tester) async {
    final focusNode = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InputSegment(
            type: SegmentType.month,
            value: 6,
            onChanged: (_) {},
            onNext: () {},
            onPrevious: () {},
            focusNode: focusNode,
          ),
        ),
      ),
    );
    expect(find.text('06'), findsOneWidget);
  });

  testWidgets('InputSegment arrow up increments value', (tester) async {
    int changedValue = 0;
    final focusNode = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InputSegment(
            type: SegmentType.hour,
            value: 10,
            onChanged: (v) => changedValue = v,
            onNext: () {},
            onPrevious: () {},
            focusNode: focusNode,
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(changedValue, 11);
  });
}
