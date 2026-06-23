import 'package:flutter/material.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDayOfWeekIsMonday = true,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool firstDayOfWeekIsMonday;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  @override
  void didUpdateWidget(covariant CalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate.year != oldWidget.selectedDate.year ||
        widget.selectedDate.month != oldWidget.selectedDate.month) {
      _displayMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    }
  }

  List<String> get _weekDays {
    final days = ['一', '二', '三', '四', '五', '六', '日'];
    return widget.firstDayOfWeekIsMonday ? days : ['日', ...days.sublist(0, 6)];
  }

  int get _firstWeekdayOffset {
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final weekday = firstDay.weekday;
    return widget.firstDayOfWeekIsMonday ? weekday - 1 : weekday % 7;
  }

  int get _daysInMonth {
    final nextMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  void _previousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
            ),
            Text(
              '${_displayMonth.year}年${_displayMonth.month}月',
              style: theme.textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekDays.map((day) => SizedBox(
            width: 32,
            child: Text(day, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          )).toList(),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 7,
          childAspectRatio: 1.2,
          children: [
            ...List.generate(_firstWeekdayOffset, (_) => const SizedBox.shrink()),
            ...List.generate(_daysInMonth, (index) {
              final day = index + 1;
              final date = DateTime(_displayMonth.year, _displayMonth.month, day);
              final isSelected = date.year == widget.selectedDate.year &&
                  date.month == widget.selectedDate.month &&
                  date.day == widget.selectedDate.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return InkWell(
                onTap: () => widget.onDateSelected(date),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : (isToday ? colorScheme.primaryContainer : null),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? colorScheme.onPrimary : null,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
