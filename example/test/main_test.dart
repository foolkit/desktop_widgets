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

  testWidgets('fullscreen demo exposes the expected interaction structure', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(760, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fullscreen'));
    await tester.pumpAndSettle();

    expect(find.text('Status Panel'), findsOneWidget);
    expect(find.text('Overlay fallback'), findsOneWidget);
    expect(find.text('Focused space'), findsWidgets);
    expect(find.text('Workspace Canvas'), findsOneWidget);
    expect(find.text('Actions'), findsOneWidget);
    expect(find.text('Open Overlay Preview'), findsOneWidget);
    expect(find.text('Exit Overlay Preview'), findsOneWidget);

    expect(find.text('Focus: Inbox Review'), findsOneWidget);
    await tester.tap(find.text('Launch Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Focus: Launch Notes'), findsOneWidget);

    await tester.ensureVisible(find.text('Open Overlay Preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Overlay Preview'));
    await tester.pumpAndSettle();

    final overlaySurface = find.byKey(
      const ValueKey<String>('fullscreen-demo-overlay-surface'),
    );
    expect(overlaySurface, findsOneWidget);

    final overlaySize = tester.getSize(overlaySurface);
    expect(overlaySize.width, greaterThanOrEqualTo(720));
    expect(overlaySize.height, greaterThanOrEqualTo(1760));
  });
}
