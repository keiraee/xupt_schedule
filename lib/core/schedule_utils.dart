import '../core/constants.dart';

class PeriodRange {
  const PeriodRange({
    required this.start,
    required this.end,
    required this.rowspan,
    required this.startKey,
    required this.endKey,
  });

  final int start;
  final int end;
  final int rowspan;
  final String startKey;
  final String endKey;
}

String maskStudentId(String value) {
  final text = value;
  if (text.length > 6) {
    return '${text.substring(0, 3)}••••${text.substring(text.length - 2)}';
  }
  return text;
}

DateTime startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day, 12);
}

DateTime startOfWeek(DateTime value) {
  final date = startOfDay(value);
  return date.subtract(Duration(days: (date.weekday - 1)));
}

bool sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime addDays(DateTime value, int days) {
  return startOfDay(value).add(Duration(days: days));
}

String formatShortDate(DateTime date) {
  return '${date.month}月${date.day}日';
}

String formatRangeDate(DateTime date) {
  return '${date.month}/${date.day}';
}

String normalizeTermLabel(String? label) {
  var text = (label ?? '').replaceAll(RegExp(r'\s'), '');
  text = text.replaceAll('(', '（').replaceAll(')', '）');
  return text;
}

DateTime? defaultTermStart(String? termLabel) {
  final normalized = normalizeTermLabel(termLabel);
  if (normalized.isEmpty) return null;
  final known = AppConstants.knownTermStarts[normalized];
  if (known != null) {
    final parts = known.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      12,
    );
  }

  final match = RegExp(r'(\d{4})-(\d{4}).*（([一二])）').firstMatch(normalized);
  if (match == null) return null;

  if (match.group(3) == '一') {
    final anchor = DateTime(int.parse(match.group(1)!), 9, 1, 12);
    return anchor.subtract(Duration(days: (anchor.weekday - 1)));
  }

  final anchor = DateTime(int.parse(match.group(2)!), 3, 1, 12);
  final offset = (DateTime.monday + 7 - anchor.weekday) % 7;
  return addDays(anchor, offset);
}

DateTime? resolveTermStart(String? week1Start, String? termLabel) {
  if (week1Start != null && week1Start.isNotEmpty) {
    final parts = week1Start.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      12,
    );
  }
  return defaultTermStart(termLabel);
}

int? academicWeek(DateTime date, DateTime? termStart) {
  if (termStart == null) return null;
  final diff = startOfDay(date).difference(startOfDay(termStart)).inDays;
  return (diff ~/ 7) + 1;
}

String periodLabel(String key) {
  if (key.startsWith('中午')) {
    return '中午第${key.substring(2)}节';
  }
  return '第$key节';
}

PeriodRange periodRange(String period) {
  final parts = period
      .split('-')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  final startKey = parts.isNotEmpty ? parts.first : '1';
  final endKey = parts.isNotEmpty ? parts.last : startKey;
  var start = AppConstants.periods.indexOf(startKey);
  var end = AppConstants.periods.indexOf(endKey);
  if (start < 0) start = 0;
  if (end < 0) end = start;
  if (end < start) end = start;
  return PeriodRange(
    start: start,
    end: end,
    rowspan: end - start + 1,
    startKey: startKey,
    endKey: endKey,
  );
}

String weekRule({
  required int weekStart,
  required int weekEnd,
  required String weekPattern,
}) {
  final range = weekStart == weekEnd ? '$weekStart' : '$weekStart–$weekEnd';
  return '第 $range 周 · $weekPattern';
}

String periodTimeRange({
  required String period,
  required Map<String, String> periodTimes,
}) {
  final range = periodRange(period);
  final times = periodTimes.isNotEmpty ? periodTimes : AppConstants.defaultTimes;
  final first = times[range.startKey] ?? AppConstants.defaultTimes[range.startKey] ?? '';
  final last = times[range.endKey] ?? AppConstants.defaultTimes[range.endKey] ?? first;
  final start = first.split('-').first;
  final end = last.split('-').last;
  final label = range.start == range.end
      ? periodLabel(range.startKey)
      : '${periodLabel(range.startKey)}–${periodLabel(range.endKey)}';
  return '$label · $start–$end';
}
