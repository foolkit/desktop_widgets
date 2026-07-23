import 'package:desktop_widgets/desktop_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'fullscreen_demo.dart';
import 'side_split_layout_demo.dart';
import 'split_layout_demo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureDesktopWindow();
  runApp(const MyApp());
}

Future<void> _configureDesktopWindow() async {
  if (kIsWeb || !_isDesktopPlatform()) {
    return;
  }

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1280, 860),
    minimumSize: Size(960, 640),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    title: 'Desktop Widgets Demo',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

bool _isDesktopPlatform() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      return true;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Desktop Widgets Demo',
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Desktop Widgets Demo'),
            bottom: const TabBar(
              tabs: <Widget>[
                Tab(text: 'DateTimePicker'),
                Tab(text: 'SideSplitLayout'),
                Tab(text: 'SplitLayout'),
                Tab(text: 'Fullscreen'),
              ],
            ),
          ),
          body: const TabBarView(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(24),
                child: DateTimePickerDemo(),
              ),
              SideSplitLayoutDemo(),
              SplitLayoutDemo(),
              FullscreenDemo(),
            ],
          ),
        ),
      ),
    );
  }
}

class DateTimePickerDemo extends StatefulWidget {
  const DateTimePickerDemo({super.key});

  @override
  State<DateTimePickerDemo> createState() => _DateTimePickerDemoState();
}

class _DateTimePickerDemoState extends State<DateTimePickerDemo> {
  DateTime _value = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selected: $_value', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        DateTimePicker(
          initialValue: _value,
          onChanged: (v) => setState(() => _value = v),
        ),
        const SizedBox(height: 16),
        DateTimePicker(
          initialValue: _value,
          format: const DateTimeFormatConfig(dateFirst: false),
          showSeconds: false,
          onChanged: (v) => setState(() => _value = v),
          panelMaxHeight: 400,
        ),
      ],
    );
  }
}
