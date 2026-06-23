import 'package:flutter/material.dart';
import 'inline_dropdown.dart';

class TimeSelector extends StatelessWidget {
  const TimeSelector({
    super.key,
    required this.hour,
    required this.minute,
    required this.second,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onSecondChanged,
    this.showSeconds = true,
  });

  final int hour;
  final int minute;
  final int second;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final ValueChanged<int> onSecondChanged;
  final bool showSeconds;

  List<DropdownMenuItem<int>> _buildItems(int min, int max) {
    return List.generate(max - min + 1, (i) {
      final v = min + i;
      return DropdownMenuItem(
        value: v,
        child: Text(v.toString().padLeft(2, '0')),
      );
    });
  }

  Widget _buildDropdown(String label, int value, List<DropdownMenuItem<int>> items, ValueChanged<int> onChanged) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        InlineDropdown<int>(
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hourItems = _buildItems(0, 23);
    final minuteItems = _buildItems(0, 59);
    final secondItems = _buildItems(0, 59);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown('时', hour, hourItems, onHourChanged),
        const Padding(
          padding: EdgeInsets.only(top: 24, left: 4, right: 4),
          child: Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        _buildDropdown('分', minute, minuteItems, onMinuteChanged),
        if (showSeconds) ...[
          const Padding(
            padding: EdgeInsets.only(top: 24, left: 4, right: 4),
            child: Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          _buildDropdown('秒', second, secondItems, onSecondChanged),
        ],
      ],
    );
  }
}
