import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:desktop_widgets_example/side_split_layout_demo.dart';

void main() {
  testWidgets('hides the search panel in demo without runtime exceptions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SideSplitLayoutDemo())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Main area'), findsOneWidget);
    expect(find.textContaining('Current selection:'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggles search panel on every tap', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SideSplitLayoutDemo())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Current selection: Search'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.textContaining('Current selection: None'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.textContaining('Current selection: Search'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.textContaining('Current selection: None'), findsOneWidget);
  });

  testWidgets(
    'toggles correctly after external hide and reselect',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SideSplitLayoutDemo())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hide Panel'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Current selection: None'), findsOneWidget);

      await tester.tap(find.text('Select Search'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Current selection: Search'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.textContaining('Current selection: None'), findsOneWidget);
    },
  );
}
