import 'package:flutter_test/flutter_test.dart';

import 'package:desktop_widgets_example/main.dart';

void main() {
  testWidgets('shows the SideSplitLayout demo tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('SideSplitLayout'));
    await tester.pumpAndSettle();

    expect(find.text('Main area'), findsOneWidget);
    expect(find.textContaining('Current selection:'), findsOneWidget);
    expect(
      find.text(
        'Switch from Search to Settings to see the width animate continuously from A to B.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Use the external buttons to verify controlled mode stays stable during animation.',
      ),
      findsOneWidget,
    );
  });
}
