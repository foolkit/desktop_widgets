import 'package:flutter/material.dart';
import 'calendar_view.dart';
import 'time_selector.dart';

class DateTimePickerPanel extends StatelessWidget {
  const DateTimePickerPanel({
    super.key,
    required this.value,
    required this.onChanged,
    required this.showSeconds,
    required this.firstDayOfWeekIsMonday,
    this.width = 320,
    this.maxHeight,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool showSeconds;
  final bool firstDayOfWeekIsMonday;
  final double width;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final panelContent = Container(
      width: width,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CalendarView(
            selectedDate: value,
            onDateSelected: (date) {
              onChanged(DateTime(
                date.year,
                date.month,
                date.day,
                value.hour,
                value.minute,
                value.second,
              ));
            },
            firstDayOfWeekIsMonday: firstDayOfWeekIsMonday,
          ),
          const Divider(),
          TimeSelector(
            hour: value.hour,
            minute: value.minute,
            second: value.second,
            onHourChanged: (h) => onChanged(DateTime(
              value.year, value.month, value.day, h, value.minute, value.second,
            )),
            onMinuteChanged: (m) => onChanged(DateTime(
              value.year, value.month, value.day, value.hour, m, value.second,
            )),
            onSecondChanged: (s) => onChanged(DateTime(
              value.year, value.month, value.day, value.hour, value.minute, s,
            )),
            showSeconds: showSeconds,
          ),
        ],
      ),
    );

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: maxHeight ?? double.infinity,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: maxHeight == null
            ? panelContent
            : SingleChildScrollView(
                child: panelContent,
              ),
      ),
    );
  }
}
