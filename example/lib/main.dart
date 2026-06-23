import 'package:flutter/material.dart';
import 'package:desktop_widgets/desktop_widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Desktop Widgets Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('DateTimePicker Demo')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: DateTimePickerDemo(),
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
