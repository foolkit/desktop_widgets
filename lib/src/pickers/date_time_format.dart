enum DateOrder { ymd, dmy, mdy }

class DateTimeFormatConfig {
  const DateTimeFormatConfig({
    this.dateFirst = true,
    this.dateOrder = DateOrder.ymd,
    this.dateSeparator = '-',
    this.timeSeparator = ':',
  });

  final bool dateFirst;
  final DateOrder dateOrder;
  final String dateSeparator;
  final String timeSeparator;

  String format(DateTime dt, {bool showSeconds = true}) {
    final dateStr = switch (dateOrder) {
      DateOrder.ymd => '${dt.year.toString().padLeft(4, '0')}$dateSeparator${dt.month.toString().padLeft(2, '0')}$dateSeparator${dt.day.toString().padLeft(2, '0')}',
      DateOrder.dmy => '${dt.day.toString().padLeft(2, '0')}$dateSeparator${dt.month.toString().padLeft(2, '0')}$dateSeparator${dt.year.toString().padLeft(4, '0')}',
      DateOrder.mdy => '${dt.month.toString().padLeft(2, '0')}$dateSeparator${dt.day.toString().padLeft(2, '0')}$dateSeparator${dt.year.toString().padLeft(4, '0')}',
    };
    final timeStr = showSeconds
        ? '${dt.hour.toString().padLeft(2, '0')}$timeSeparator${dt.minute.toString().padLeft(2, '0')}$timeSeparator${dt.second.toString().padLeft(2, '0')}'
        : '${dt.hour.toString().padLeft(2, '0')}$timeSeparator${dt.minute.toString().padLeft(2, '0')}';
    return dateFirst ? '$dateStr $timeStr' : '$timeStr $dateStr';
  }

  List<SegmentType> getSegmentTypes({bool showSeconds = true}) {
    final dateSegments = switch (dateOrder) {
      DateOrder.ymd => [SegmentType.year, SegmentType.month, SegmentType.day],
      DateOrder.dmy => [SegmentType.day, SegmentType.month, SegmentType.year],
      DateOrder.mdy => [SegmentType.month, SegmentType.day, SegmentType.year],
    };
    final timeSegments = showSeconds
        ? [SegmentType.hour, SegmentType.minute, SegmentType.second]
        : [SegmentType.hour, SegmentType.minute];
    return dateFirst
        ? [...dateSegments, ...timeSegments]
        : [...timeSegments, ...dateSegments];
  }
}

enum SegmentType { year, month, day, hour, minute, second }
