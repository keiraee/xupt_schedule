import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants.dart';
import '../../../core/schedule_utils.dart';
import '../../../data/school/school_client.dart';

/// 周课表：宽度撑满、高度按剩余空间均分，连排课跨行叠在格子上。
class WeekTimetable extends StatelessWidget {
  const WeekTimetable({
    super.key,
    required this.dates,
    required this.eventsForDate,
  });

  final List<DateTime> dates;
  final List<ScheduleEvent> Function(DateTime date) eventsForDate;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final breakCount = AppConstants.sectionBreaks.length;
    final budgetH = media.size.height -
        media.padding.top -
        media.padding.bottom -
        190;
    const headerH = 36.0;
    const breakH = 15.0;
    final rowH = ((budgetH - headerH - breakCount * breakH) /
            AppConstants.periods.length)
        .clamp(28.0, 64.0);
    final totalH =
        headerH + AppConstants.periods.length * rowH + breakCount * breakH;

    return Container(
      height: totalH,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: _Grid(
        dates: dates,
        eventsForDate: eventsForDate,
        headerH: headerH,
        breakH: breakH,
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.dates,
    required this.eventsForDate,
    required this.headerH,
    required this.breakH,
  });

  final List<DateTime> dates;
  final List<ScheduleEvent> Function(DateTime date) eventsForDate;
  final double headerH;
  final double breakH;

  static const _periodW = 44.0;

  double _periodTop(int p, double rowH) {
    var y = headerH;
    for (var i = 0; i <= p; i++) {
      if (AppConstants.sectionBreaks.containsKey(i)) y += breakH;
      if (i < p) y += rowH;
    }
    return y;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final periodCount = AppConstants.periods.length;
        final breakCount = AppConstants.sectionBreaks.length;
        final rowH =
            (constraints.maxHeight - headerH - breakCount * breakH) /
                periodCount;
        final dayW = (constraints.maxWidth - _periodW) / 7;

        final rows = <Widget>[
          SizedBox(
            height: headerH,
            child: Row(
              children: [
                const _PeriodHeadCell(),
                for (var i = 0; i < 7; i++)
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

        for (var p = 0; p < periodCount; p++) {
          final section = AppConstants.sectionBreaks[p];
          if (section != null) {
            rows.add(
              Container(
                height: breakH,
                color: AppTheme.soft,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  section,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.faint,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            );
          }
          rows.add(
            Expanded(
              child: _PeriodRow(
                p: p,
                dates: dates,
                today: today,
              ),
            ),
          );
        }

        final cards = <Widget>[];
        for (var d = 0; d < 7; d++) {
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
              final top = _periodTop(range.start, rowH);
              final height =
                  _periodTop(range.end, rowH) + rowH - top;
              cards.add(
                Positioned(
                  left: _periodW + d * dayW + i * splitW + 1.5,
                  top: top + 1.5,
                  width: splitW - 3,
                  height: (height - 3).clamp(0.0, double.infinity),
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
            Column(children: rows),
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
      width: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppTheme.line),
          bottom: BorderSide(color: AppTheme.lineStrong),
        ),
      ),
      child: const Text(
        '节次',
        style: TextStyle(fontSize: 10, color: AppTheme.muted),
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isToday ? Colors.white : AppTheme.ink,
            ),
          ),
          Text(
            '${date.month}/${date.day}',
            style: TextStyle(
              fontSize: 9,
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 44,
          decoration: const BoxDecoration(
            color: AppTheme.soft,
            border: Border(
              right: BorderSide(color: AppTheme.line),
              bottom: BorderSide(color: AppTheme.line),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    period.startsWith('中午')
                        ? '午${period.substring(2)}'
                        : period,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (parts.isNotEmpty)
                    Text(
                      parts.first,
                      style: const TextStyle(fontSize: 7.5, color: AppTheme.muted),
                    ),
                  if (parts.length > 1)
                    Text(
                      parts.last,
                      style: const TextStyle(fontSize: 7.5, color: AppTheme.muted),
                    ),
                ],
              ),
            ),
          ),
        ),
          for (var d = 0; d < 7; d++)
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
    final startT =
        (AppConstants.defaultTimes[r.startKey] ?? '').split('-').first;
    final endT = (AppConstants.defaultTimes[r.endKey] ?? '').split('-').last;
    final bg = _palette[event.course.hashCode.abs() % _palette.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? const Border.fromBorderSide(
                BorderSide(color: AppTheme.ink, width: 0.8),
              )
            : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, box) {
          final showTime = box.maxHeight >= 28;
          final showLoc = event.location.isNotEmpty && box.maxHeight >= 42;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.course,
                  maxLines: r.rowspan >= 3 ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                    height: 1.15,
                  ),
                ),
              ),
              if (showLoc)
                Text(
                  event.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
              if (showTime)
                Text(
                  r.rowspan > 1
                      ? '$startT-$endT · ${r.rowspan}节'
                      : '$startT-$endT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppTheme.muted,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
