import 'package:flutter_test/flutter_test.dart';
import 'package:xupt_schedule_app/core/schedule_utils.dart';

void main() {
  test('中午2-6 spans afternoon rows without wrapping to 中午1', () {
    final range = periodRange('中午2-6');
    expect(range.startKey, '中午2');
    expect(range.endKey, '6');
    expect(range.rowspan, 3);
  });

  test('9-11 is three evening periods', () {
    final range = periodRange('9-11');
    expect(range.startKey, '9');
    expect(range.endKey, '11');
    expect(range.rowspan, 3);
  });

  test('2026 fall term starts on the Monday of Sep 1 week', () {
    final start = defaultTermStart('2026-2027（一）');
    expect(start, isNotNull);
    expect(start!.weekday, DateTime.monday);
    expect(academicWeek(DateTime(2026, 9, 13, 12), start), 2);
  });
}
