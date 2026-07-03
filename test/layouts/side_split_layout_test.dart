import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_widgets/src/layouts/side_split_layout.dart';

class _CounterPanel extends StatefulWidget {
  const _CounterPanel({required this.label});

  final String label;

  @override
  State<_CounterPanel> createState() => _CounterPanelState();
}

class _CounterPanelState extends State<_CounterPanel> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('${widget.label}: $_count'),
          TextButton(
            onPressed: () => setState(() => _count++),
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('SideSplitLayout', () {
    testWidgets('displays main child and no side panel by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.text('Panel 0'), findsNothing);
    });

    testWidgets('shows one panel when its button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
                SidePanel(button: Icon(Icons.settings), panel: Text('Panel 1')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Panel 0'), findsOneWidget);
      expect(find.text('Panel 1'), findsNothing);
    });

    testWidgets('only one panel is visible at a time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
                SidePanel(button: Icon(Icons.settings), panel: Text('Panel 1')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Panel 0'), findsNothing);
      expect(find.text('Panel 1'), findsOneWidget);
    });

    testWidgets('toggles off active panel when tapped again', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Panel 0'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Panel 0'), findsNothing);
    });

    testWidgets('supports initialSelectedIndex in uncontrolled mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              initialSelectedIndex: 0,
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      expect(find.text('Panel 0'), findsOneWidget);
    });

    testWidgets('calls onSelectedIndexChanged with correct index', (
      tester,
    ) async {
      int? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
              ],
              onSelectedIndexChanged: (index) => captured = index,
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      expect(captured, 0);

      await tester.tap(find.byIcon(Icons.search));
      expect(captured, isNull);
    });

    testWidgets('keeps alive panel state when keepAlive is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              panels: const [
                SidePanel(
                  button: Icon(Icons.search),
                  keepAlive: true,
                  panel: _CounterPanel(label: 'Panel 0'),
                ),
              ],
              child: Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Panel 0: 0'), findsOneWidget);

      await tester.tap(find.text('Increment'));
      await tester.pumpAndSettle();
      expect(find.text('Panel 0: 1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Panel 0: 1'), findsNothing);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Panel 0: 1'), findsOneWidget);
    });

    testWidgets('animates panel width when opening and closing', (
      tester,
    ) async {
      const animatedPanelKey = ValueKey<String>('sideSplitLayoutAnimatedPanel');
      const animationDuration = Duration(milliseconds: 400);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              panelWidth: 240,
              panelAnimationDuration: animationDuration,
              panelAnimationCurve: Curves.linear,
              panels: const [
                SidePanel(
                  button: Icon(Icons.search),
                  keepAlive: true,
                  panel: Text('Panel 0'),
                ),
              ],
              child: Text('Main Content'),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(animatedPanelKey)).width, 0);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final openingWidth = tester.getSize(find.byKey(animatedPanelKey)).width;
      expect(openingWidth, moreOrLessEquals(120, epsilon: 1));

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(animatedPanelKey)).width, 240);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final closingWidth = tester.getSize(find.byKey(animatedPanelKey)).width;
      expect(closingWidth, moreOrLessEquals(120, epsilon: 1));

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(animatedPanelKey)).width, 0);
    });

    testWidgets('animates resize handle width when opening and closing', (
      tester,
    ) async {
      const handleKey = ValueKey<String>('sideSplitLayoutAnimatedResizeHandle');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              panelWidth: 240,
              panelAnimationDuration: const Duration(milliseconds: 400),
              panelAnimationCurve: Curves.linear,
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(handleKey)).width, 0);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        tester.getSize(find.byKey(handleKey)).width,
        moreOrLessEquals(4, epsilon: 0.5),
      );

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(handleKey)).width, 8);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        tester.getSize(find.byKey(handleKey)).width,
        moreOrLessEquals(4, epsilon: 0.5),
      );

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(handleKey)).width, 0);
    });

    testWidgets('animates continuously from panel A width to panel B width', (
      tester,
    ) async {
      const animatedPanelKey = ValueKey<String>('sideSplitLayoutAnimatedPanel');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              panelWidth: 240,
              panelAnimationDuration: const Duration(milliseconds: 400),
              panelAnimationCurve: Curves.linear,
              mainPosition: SideSplitMainPosition.end,
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
                SidePanel(button: Icon(Icons.settings), panel: Text('Panel 1')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey<String>('sideSplitLayoutResizer')),
        const Offset(120, 0),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byKey(animatedPanelKey)).width, 360);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final transitioningWidth = tester
          .getSize(find.byKey(animatedPanelKey))
          .width;
      expect(transitioningWidth, moreOrLessEquals(300, epsilon: 1));

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(animatedPanelKey)).width, 240);
      expect(find.text('Panel 1'), findsOneWidget);
      expect(find.text('Panel 0'), findsNothing);
    });

    testWidgets('renders extra buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              extraButtons: const [Icon(Icons.add)],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('uses controlled selectedIndex', (tester) async {
      int? selected = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SideSplitLayout(
                panels: const [
                  SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
                  SidePanel(
                    button: Icon(Icons.settings),
                    panel: Text('Panel 1'),
                  ),
                ],
                selectedIndex: selected,
                onSelectedIndexChanged: (index) =>
                    setState(() => selected = index),
                child: const Text('Main Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Panel 1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Panel 0'), findsOneWidget);
      expect(find.text('Panel 1'), findsNothing);
    });

    testWidgets(
      'toggles correctly with controlled selectedIndex on fast repeated taps',
      (tester) async {
        int? selected;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => SideSplitLayout(
                  panels: const [
                    SidePanel(
                      button: Icon(Icons.search),
                      panel: Text('Panel 0'),
                    ),
                  ],
                  selectedIndex: selected,
                  onSelectedIndexChanged: (index) =>
                      setState(() => selected = index),
                  child: const Text('Main Content'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.search));
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        expect(find.text('Panel 0'), findsNothing);
      },
    );

    testWidgets('animates width changes in controlled mode', (tester) async {
      const animatedPanelKey = ValueKey<String>('sideSplitLayoutAnimatedPanel');
      int? selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: <Widget>[
                  TextButton(
                    onPressed: () => setState(() => selected = 1),
                    child: const Text('Select Panel 1'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => selected = null),
                    child: const Text('Hide Panel'),
                  ),
                  Expanded(
                    child: SideSplitLayout(
                      panelWidth: 240,
                      panelAnimationDuration: const Duration(milliseconds: 400),
                      panelAnimationCurve: Curves.linear,
                      selectedIndex: selected,
                      panels: const [
                        SidePanel(
                          button: Icon(Icons.search),
                          panel: Text('Panel 0'),
                        ),
                        SidePanel(
                          button: Icon(Icons.settings),
                          panel: Text('Panel 1'),
                        ),
                      ],
                      child: const Text('Main Content'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(animatedPanelKey)).width, 240);

      await tester.tap(find.text('Hide Panel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.getSize(find.byKey(animatedPanelKey)).width,
        moreOrLessEquals(120, epsilon: 1),
      );

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(animatedPanelKey)).width, 0);

      await tester.tap(find.text('Select Panel 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.getSize(find.byKey(animatedPanelKey)).width,
        moreOrLessEquals(120, epsilon: 1),
      );

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(animatedPanelKey)).width, 240);
      expect(find.text('Panel 1'), findsOneWidget);
      expect(find.text('Panel 0'), findsNothing);
    });

    testWidgets(
      'toggles off with one tap even when tapped during opening animation in controlled mode',
      (tester) async {
        const animatedPanelKey = ValueKey<String>(
          'sideSplitLayoutAnimatedPanel',
        );
        int? selected;
        final events = <int?>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => SideSplitLayout(
                  panelWidth: 240,
                  panelAnimationDuration: const Duration(milliseconds: 400),
                  panelAnimationCurve: Curves.linear,
                  selectedIndex: selected,
                  onSelectedIndexChanged: (index) {
                    events.add(index);
                    setState(() => selected = index);
                  },
                  panels: const [
                    SidePanel(
                      button: Icon(Icons.search),
                      panel: Text('Panel 0'),
                    ),
                  ],
                  child: const Text('Main Content'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          tester.getSize(find.byKey(animatedPanelKey)).width,
          greaterThan(0),
        );

        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        expect(events, <int?>[0, null]);
        expect(selected, isNull);
        expect(
          tester
              .widget<SideSplitLayout>(find.byType(SideSplitLayout))
              .selectedIndex,
          isNull,
        );
        expect(find.text('Panel 0'), findsNothing);
      },
    );

    testWidgets('panel uses default width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byKey(const ValueKey<int>(0)));
      expect(size.width, 250);
    });

    testWidgets('resizes panel by dragging divider to the right', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              mainPosition: SideSplitMainPosition.end,
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey<String>('sideSplitLayoutResizer')),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byKey(const ValueKey<int>(0)));
      expect(size.width, 350);
    });

    testWidgets('reverses drag direction when main panel is on the left', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              mainPosition: SideSplitMainPosition.start,
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey<String>('sideSplitLayoutResizer')),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byKey(const ValueKey<int>(0)));
      expect(size.width, 150);

      await tester.drag(
        find.byKey(const ValueKey<String>('sideSplitLayoutResizer')),
        const Offset(-100, 0),
      );
      await tester.pumpAndSettle();

      final size2 = tester.getSize(find.byKey(const ValueKey<int>(0)));
      expect(size2.width, 250);
    });

    testWidgets('clamps panel width to minimum', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              mainPosition: SideSplitMainPosition.end,
              minPanelWidth: 120,
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey<String>('sideSplitLayoutResizer')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byKey(const ValueKey<int>(0)));
      expect(size.width, 120);
    });

    testWidgets('each panel remembers its own width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              mainPosition: SideSplitMainPosition.end,
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
                SidePanel(button: Icon(Icons.settings), panel: Text('Panel 1')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey<String>('sideSplitLayoutResizer')),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();

      final size0 = tester.getSize(find.byKey(const ValueKey<int>(0)));
      expect(size0.width, 350);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      final size1 = tester.getSize(find.byKey(const ValueKey<int>(1)));
      expect(size1.width, 250);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final size0Again = tester.getSize(find.byKey(const ValueKey<int>(0)));
      expect(size0Again.width, 350);
    });

    testWidgets('places sidebar on the right by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final sidebarRect = tester.getRect(find.byIcon(Icons.search));
      final panelRect = tester.getRect(find.text('Panel 0'));

      expect(sidebarRect.right, greaterThan(panelRect.right));
    });

    testWidgets('places sidebar on the left when mainPosition is end', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideSplitLayout(
              mainPosition: SideSplitMainPosition.end,
              panels: const [
                SidePanel(button: Icon(Icons.search), panel: Text('Panel 0')),
              ],
              child: const Text('Main Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final sidebarRect = tester.getRect(find.byIcon(Icons.search));
      final panelRect = tester.getRect(find.text('Panel 0'));

      expect(sidebarRect.left, lessThan(panelRect.left));
    });
  });
}
