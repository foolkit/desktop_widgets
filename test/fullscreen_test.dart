import 'package:desktop_widgets/desktop_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fullscreen', () {
    testWidgets('controller shows and switches registered targets', (
      tester,
    ) async {
      final controller = FullscreenController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenScope(
              controller: controller,
              child: Column(
                children: <Widget>[
                  FullscreenTarget(
                    identifier: 'alpha',
                    fullscreenChild: const Text('Fullscreen alpha'),
                    child: const SizedBox(
                      key: ValueKey<String>('inline-alpha'),
                      child: Text('Inline alpha'),
                    ),
                  ),
                  FullscreenTarget(
                    identifier: 'beta',
                    fullscreenChild: const Text('Fullscreen beta'),
                    child: const SizedBox(
                      key: ValueKey<String>('inline-beta'),
                      child: Text('Inline beta'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Fullscreen alpha'), findsNothing);
      expect(controller.isFullscreen, isFalse);

      controller.show('alpha');
      await tester.pumpAndSettle();

      expect(controller.isFullscreen, isTrue);
      expect(controller.activeIdentifier, 'alpha');
      expect(find.text('Fullscreen alpha'), findsOneWidget);
      expect(find.text('Fullscreen beta'), findsNothing);

      controller.show('beta');
      await tester.pumpAndSettle();

      expect(controller.activeIdentifier, 'beta');
      expect(find.text('Fullscreen alpha'), findsNothing);
      expect(find.text('Fullscreen beta'), findsOneWidget);

      controller.hide();
      await tester.pumpAndSettle();

      expect(controller.isFullscreen, isFalse);
      expect(controller.activeIdentifier, isNull);
      expect(find.text('Fullscreen beta'), findsNothing);
    });

    testWidgets('pressing escape exits fullscreen', (tester) async {
      final controller = FullscreenController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenScope(
              controller: controller,
              child: FullscreenTarget(
                identifier: 'alpha',
                fullscreenChild: const Text('Fullscreen alpha'),
                child: const Text('Inline alpha'),
              ),
            ),
          ),
        ),
      );

      controller.show('alpha');
      await tester.pumpAndSettle();

      expect(find.text('Fullscreen alpha'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(controller.isFullscreen, isFalse);
      expect(find.text('Fullscreen alpha'), findsNothing);
    });

    testWidgets('tapping barrier dismisses fullscreen when enabled', (
      tester,
    ) async {
      final controller = FullscreenController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenScope(
              controller: controller,
              dismissOnBarrierTap: true,
              child: FullscreenTarget(
                identifier: 'alpha',
                fullscreenChild: const SizedBox(
                  width: 120,
                  height: 120,
                  child: ColoredBox(color: Colors.blue),
                ),
                child: const Text('Inline alpha'),
              ),
            ),
          ),
        ),
      );

      controller.show('alpha');
      await tester.pumpAndSettle();

      expect(controller.isFullscreen, isTrue);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(controller.isFullscreen, isFalse);
    });

    testWidgets('tapping barrier does not dismiss fullscreen when disabled', (
      tester,
    ) async {
      final controller = FullscreenController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenScope(
              controller: controller,
              dismissOnBarrierTap: false,
              child: FullscreenTarget(
                identifier: 'alpha',
                fullscreenChild: const SizedBox(
                  width: 120,
                  height: 120,
                  child: ColoredBox(color: Colors.blue),
                ),
                child: const Text('Inline alpha'),
              ),
            ),
          ),
        ),
      );

      controller.show('alpha');
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(controller.isFullscreen, isTrue);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('repeated show does not create duplicate fullscreen overlay', (
      tester,
    ) async {
      final controller = FullscreenController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenScope(
              controller: controller,
              child: FullscreenTarget(
                identifier: 'alpha',
                fullscreenChild: const Text('Fullscreen alpha'),
                child: const Text('Inline alpha'),
              ),
            ),
          ),
        ),
      );

      controller.show('alpha');
      await tester.pumpAndSettle();
      controller.show('alpha');
      await tester.pumpAndSettle();

      expect(find.text('Fullscreen alpha'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets(
      'registering fullscreen target during AnimatedBuilder rebuild does not mutate overlay during build',
      (tester) async {
        final controller = FullscreenController()..show('alpha');
        final notifier = ValueNotifier<int>(0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedBuilder(
                animation: notifier,
                builder: (BuildContext context, Widget? child) {
                  return FullscreenScope(
                    controller: controller,
                    child: FullscreenTarget(
                      identifier: 'alpha',
                      fullscreenChild: const Text('Fullscreen alpha'),
                      child: Text('Inline alpha ${notifier.value}'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        notifier.value = 1;
        await tester.pump();

        expect(tester.takeException(), isNull);
        await tester.pump();
        expect(find.text('Fullscreen alpha'), findsOneWidget);
      },
    );
  });
}
