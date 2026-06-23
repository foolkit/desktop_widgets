import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_widgets/src/pickers/date_time_format.dart';

void main() {
  test('default format ymd dateFirst', () {
    const config = DateTimeFormatConfig();
    final dt = DateTime(2026, 6, 17, 9, 30, 45);
    expect(config.format(dt), '2026-06-17 09:30:45');
  });

  test('dmy format', () {
    const config = DateTimeFormatConfig(dateOrder: DateOrder.dmy);
    final dt = DateTime(2026, 6, 17, 9, 30, 45);
    expect(config.format(dt), '17-06-2026 09:30:45');
  });

  test('timeFirst format', () {
    const config = DateTimeFormatConfig(dateFirst: false);
    final dt = DateTime(2026, 6, 17, 9, 30, 45);
    expect(config.format(dt), '09:30:45 2026-06-17');
  });

  test('hide seconds', () {
    const config = DateTimeFormatConfig();
    final dt = DateTime(2026, 6, 17, 9, 30, 45);
    expect(config.format(dt, showSeconds: false), '2026-06-17 09:30');
  });

  test('getSegmentTypes default', () {
    const config = DateTimeFormatConfig();
    expect(config.getSegmentTypes(), [
      SegmentType.year, SegmentType.month, SegmentType.day,
      SegmentType.hour, SegmentType.minute, SegmentType.second,
    ]);
  });

  test('getSegmentTypes dmy no seconds', () {
    const config = DateTimeFormatConfig(dateOrder: DateOrder.dmy);
    expect(config.getSegmentTypes(showSeconds: false), [
      SegmentType.day, SegmentType.month, SegmentType.year,
      SegmentType.hour, SegmentType.minute,
    ]);
  });
}
