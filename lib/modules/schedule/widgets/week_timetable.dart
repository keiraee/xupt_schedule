import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants.dart';
import '../../../core/schedule_utils.dart';
import '../../../data/school/school_client.dart';

/// 周一到周五课表。行高按内容来，整页滚动，卡片直接写出课名和地点。
class WeekTimetable extends StatelessWidget {
  const WeekTimetable({
    super.key,
    required this.dates,
    required this.eventsForDate,
  });

  final List<DateTime> dates;
  final List<ScheduleEvent> Function(DateTime date) eventsForDate;

  static const headerH = 42.0;
  static const breakH = 22.0;
  static const rowH = 86.0;
  static const periodW = 46.0;

  @override
  Widget build(BuildContext context) {
    final days = dates.take(AppConstants.weekdayCount).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: _Grid(
        dates: days,
        eventsForDate: eventsForDate,
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.dates,
    required this.eventsForDate,
  });

  final List<DateTime> dates;
  final List<ScheduleEvent> Function(DateTime date) eventsForDate;

  double _periodTop(int p) {
    var y = WeekTimetable.headerH;
    for (var i = 0; i <= p; i++) {
      if (AppConstants.sectionBreaks.containsKey(i)) {
        y += WeekTimetable.breakH;
      }
      if (i < p) y += WeekTimetable.rowH;
    }
    return y;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dayCount = dates.length;

    final rows = <Widget>[
      SizedBox(
        height: WeekTimetable.headerH,
        child: Row(
          children: [
            const _PeriodHeadCell(),
            for (var i = 0; i < dayCount; i++)
              Expanded(
                child: _DayHead(
                  date: dates[i],
                  label: '周${AppConstants.weekdays[i]}',
                  isToday: sameDate(dates[i], today),
                ),
              ),
          ],
        ),
      ),
    ];

    for (var p = 0; p < AppConstants.periods.length; p++) {
      final section = AppConstants.sectionBreaks[p];
      if (section != null) {
        rows.add(
          Container(
            height: WeekTimetable.breakH,
            color: AppTheme.soft,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              section,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.faint,
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      }
      rows.add(
        _PeriodRow(
          p: p,
          dates: dates,
          today: today,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dayW =
            (constraints.maxWidth - WeekTimetable.periodW) / dayCount;
        final cards = <Widget>[];
        for (var d = 0; d < dayCount; d++) {
          final events = eventsForDate(dates[d]);
          final groups = <int, List<ScheduleEvent>>{};
          for (final event in events) {
            final start = periodRange(event.period).start;
            groups.putIfAbsent(start, () => []).add(event);
          }
          for (final started in groups.values) {
            for (var i = 0; i < started.length; i++) {
              final event = started[i];
              final range = periodRange(event.period);
              final splitW = dayW / started.length;
              final top = _periodTop(range.start);
              final height = _periodTop(range.end) + WeekTimetable.rowH - top;
              cards.add(
                Positioned(
                  left: WeekTimetable.periodW + d * dayW + i * splitW + 2,
                  top: top + 2,
                  width: splitW - 4,
                  height: height - 4,
                  child: _CourseCard(
                    event: event,
                    isToday: sameDate(dates[d], today),
                  ),
                ),
              );
            }
          }
        }

        return Stack(
          children: [
            Column(mainAxisSize: MainAxisSize.min, children: rows),
            ...cards,
          ],
        );
      },
    );
  }
}

class _PeriodHeadCell extends StatelessWidget {
  const _PeriodHeadCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: WeekTimetable.periodW,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppTheme.line),
          bottom: BorderSide(color: AppTheme.lineStrong),
        ),
      ),
      child: const Text(
        '节次',
        style: TextStyle(fontSize: 11, color: AppTheme.muted),
      ),
    );
  }
}

class _DayHead extends StatelessWidget {
  const _DayHead({
    required this.date,
    required this.label,
    required this.isToday,
  });

  final DateTime date;
  final String label;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isToday ? AppTheme.ink : Colors.white,
        border: const Border(
          right: BorderSide(color: AppTheme.line),
          bottom: BorderSide(color: AppTheme.lineStrong),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isToday ? Colors.white : AppTheme.ink,
            ),
          ),
          Text(
            '${date.month}/${date.day}',
            style: TextStyle(
              fontSize: 10,
              color: isToday ? Colors.white70 : AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({
    required this.p,
    required this.dates,
    required this.today,
  });

  final int p;
  final List<DateTime> dates;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final period = AppConstants.periods[p];
    final time = AppConstants.defaultTimes[period] ?? '';
    final parts = time.split('-');

    return SizedBox(
      height: WeekTimetable.rowH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: WeekTimetable.periodW,
            decoration: const BoxDecoration(
              color: AppTheme.soft,
              border: Border(
                right: BorderSide(color: AppTheme.line),
                bottom: BorderSide(color: AppTheme.line),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  period.startsWith('中午') ? '午${period.substring(2)}' : period,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (parts.isNotEmpty)
                  Text(
                    parts.first,
                    style: const TextStyle(fontSize: 9, color: AppTheme.muted),
                  ),
                if (parts.length > 1)
                  Text(
                    parts.last,
                    style: const TextStyle(fontSize: 9, color: AppTheme.muted),
                  ),
              ],
            ),
          ),
          for (var d = 0; d < dates.length; d++)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: sameDate(dates[d], today)
                      ? AppTheme.today
                      : Colors.white,
                  border: const Border(
                    right: BorderSide(color: AppTheme.line),
                    bottom: BorderSide(color: AppTheme.line),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.event, required this.isToday});

  final ScheduleEvent event;
  final bool isToday;

  static const _palette = <Color>[
    Color(0xFFDCEBFF),
    Color(0xFFD9F2E3),
    Color(0xFFFFE8C8),
    Color(0xFFEBD9FC),
    Color(0xFFCFF3F7),
    Color(0xFFFFD6E0),
    Color(0xFFE4F5C8),
  ];

  @override
  Widget build(BuildContext context) {
    final r = periodRange(event.period);
    final bg = _palette[event.course.hashCode.abs() % _palette.length];
    final lines = r.rowspan >= 3 ? 6 : (r.rowspan >= 2 ? 4 : 3);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isToday
                ? const Border.fromBorderSide(
                    BorderSide(color: AppTheme.ink, width: 0.8),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.course,
                  maxLines: lines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                    height: 1.25,
                  ),
                ),
                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    event.location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                      height: 1.2,
                    ),
                  ),
                ],
                if (event.teacher.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.teacher,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final time = periodTimeRange(
      period: event.period,
      periodTimes: AppConstants.defaultTimes,
    );
    final weeks = weekRule(
      weekStart: event.weekStart,
      weekEnd: event.weekEnd,
      weekPattern: event.weekPattern,
    );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.course,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 12),
              _DetailLine(label: '时间', value: '周${event.weekday} · $time'),
              _DetailLine(label: '周次', value: weeks),
              if (event.location.isNotEmpty)
                _DetailLine(label: '地点', value: event.location),
              if (event.teacher.isNotEmpty)
                _DetailLine(label: '教师', value: event.teacher),
              if (event.className.isNotEmpty)
                _DetailLine(label: '班级', value: event.className),
            ],
          ),
        );
      },
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
