import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_widgets/src/layouts/split_layout.dart';

void main() {
  group('SplitLayout', () {
    testWidgets('renders two panels by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitLayout(
              panels: const [
                SplitPanel(child: Text('Panel 0')),
                SplitPanel(child: Text('Panel 1')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Panel 0'), findsOneWidget);
      expect(find.text('Panel 1'), findsOneWidget);
    });

    testWidgets('distributes width proportionally', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: SplitLayout(
                panels: [
                  SplitPanel(
                    size: 0.3,
                    child: SizedBox.expand(key: const ValueKey('panel0')),
                  ),
                  SplitPanel(
                    child: SizedBox.expand(key: const ValueKey('panel1')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final panel0 = tester.getSize(find.byKey(const ValueKey('panel0')));
      expect(panel0.width, closeTo(236, 4));
    });

    testWidgets('redistributes proportionally when container resizes',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: SplitLayout(
                panels: [
                  SplitPanel(
                    size: 0.5,
                    child: SizedBox.expand(key: const ValueKey('panel0')),
                  ),
                  SplitPanel(
                    child: SizedBox.expand(key: const ValueKey('panel1')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final panel0First = tester.getSize(find.byKey(const ValueKey('panel0')));
      expect(panel0First.width, closeTo(396, 4));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: SplitLayout(
                panels: [
                  SplitPanel(
                    size: 0.5,
                    child: SizedBox.expand(key: const ValueKey('panel0')),
                  ),
                  SplitPanel(
                    child: SizedBox.expand(key: const ValueKey('panel1')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final panel0Second = tester.getSize(find.byKey(const ValueKey('panel0')));
      expect(panel0Second.width, closeTo(196, 4));
    });

    testWidgets('distributes width by pixel priority', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: SplitLayout(
                sizeUnit: SplitSizeUnit.pixel,
                panels: [
                  SplitPanel(
                    size: 300,
                    priority: 0,
                    child: SizedBox.expand(key: const ValueKey('panel0')),
                  ),
                  SplitPanel(
                    priority: 1,
                    child: SizedBox.expand(key: const ValueKey('panel1')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final panel0 = tester.getSize(find.byKey(const ValueKey('panel0')));
      expect(panel0.width, closeTo(300, 4));
    });

    testWidgets(
        'resizes primary panel by dragging divider in proportional mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: SplitLayout(
                panels: [
                  SplitPanel(
                    child: SizedBox.expand(key: const ValueKey('panel0')),
                  ),
                  SplitPanel(
                    child: SizedBox.expand(key: const ValueKey('panel1')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('splitLayoutDivider')),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();

      final panel0 = tester.getSize(find.byKey(const ValueKey('panel0')));
      expect(panel0.width, closeTo(496, 4));
    });

    testWidgets(
        'resizes higher priority panel by dragging divider in pixel mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: SplitLayout(
                sizeUnit: SplitSizeUnit.pixel,
                panels: [
                  SplitPanel(
                    size: 300,
                    priority: 1,
                    child: SizedBox.expand(key: const ValueKey('panel0')),
                  ),
                  SplitPanel(
                    size: 200,
                    priority: 0,
                    child: SizedBox.expand(key: const ValueKey('panel1')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final panel1Before = tester.getSize(find.byKey(const ValueKey('panel1')));
      expect(panel1Before.width, closeTo(200, 4));

      await tester.drag(
        find.byKey(const ValueKey<String>('splitLayoutDivider')),
        const Offset(-100, 0),
      );
      await tester.pumpAndSettle();

      final panel1After = tester.getSize(find.byKey(const ValueKey('panel1')));
      expect(panel1After.width, closeTo(300, 4));
    });

    testWidgets('hides panel via controller', (tester) async {
      final controller = SplitLayoutController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitLayout(
              controller: controller,
              panels: const [
                SplitPanel(child: Text('Panel 0')),
                SplitPanel(child: Text('Panel 1')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Panel 0'), findsOneWidget);

      controller.setPanelVisible(0, false);
      await tester.pumpAndSettle();

      expect(find.text('Panel 0'), findsNothing);
      expect(find.text('Panel 1'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('respects min and max size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: SplitLayout(
                sizeUnit: SplitSizeUnit.pixel,
                panels: [
                  SplitPanel(
                    size: 1000,
                    minSize: 100,
                    maxSize: 400,
                    child: SizedBox.expand(key: const ValueKey('panel0')),
                  ),
                  SplitPanel(
                    child: SizedBox.expand(key: const ValueKey('panel1')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final panel0 = tester.getSize(find.byKey(const ValueKey('panel0')));
      expect(panel0.width, closeTo(400, 4));
    });

    testWidgets('does not resize when resizable is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: SplitLayout(
                resizable: false,
                panels: const [
                  SplitPanel(child: SizedBox.expand()),
                  SplitPanel(child: SizedBox.expand()),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey<String>('splitLayoutDivider')),
          findsNothing);
    });

    testWidgets('distributes height in vertical mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: SplitLayout(
                axis: SplitAxis.vertical,
                panels: [
                  SplitPanel(
                    size: 0.4,
                    child: SizedBox.expand(key: const ValueKey('panel0')),
                  ),
                  SplitPanel(
                    child: SizedBox.expand(key: const ValueKey('panel1')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final panel0 = tester.getSize(find.byKey(const ValueKey('panel0')));
      expect(panel0.height, closeTo(236, 4));
    });
  });
}
