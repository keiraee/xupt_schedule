import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants.dart';
import '../../../core/schedule_utils.dart';
import '../../../data/school/school_client.dart';

/// 当日课程列表：手机上比整周表格更好点、更好读。
class DayScheduleList extends StatelessWidget {
  const DayScheduleList({
    super.key,
    required this.events,
    required this.selectedDate,
  });

  final List<ScheduleEvent> events;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.line),
        ),
        child: const Column(
          children: [
            Icon(Icons.free_breakfast_outlined, size: 36, color: AppTheme.faint),
            SizedBox(height: 10),
            Text(
              '这一天没有课',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '左右切换日期，或点「回到今天」',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < events.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _CourseTile(
            event: events[i],
            times: AppConstants.defaultTimes,
            isNow: _isHappeningNow(events[i]),
          ),
        ],
      ],
    );
  }

  bool _isHappeningNow(ScheduleEvent event) {
    final now = DateTime.now();
    if (!sameDate(selectedDate, now)) return false;
    final range = periodRange(event.period);
    final startKey = range.startKey;
    final endKey = range.endKey;
    int? toMin(String key) {
      final raw = AppConstants.defaultTimes[key];
      if (raw == null) return null;
      final end = raw.split('-').last.trim();
      final parts = end.split(':');
      if (parts.length < 2) return null;
      return int.tryParse(parts[0])! * 60 + int.tryParse(parts[1])!;
    }

    int? fromMin(String key) {
      final raw = AppConstants.defaultTimes[key];
      if (raw == null) return null;
      final start = raw.split('-').first.trim();
      final parts = start.split(':');
      if (parts.length < 2) return null;
      return int.tryParse(parts[0])! * 60 + int.tryParse(parts[1])!;
    }

    final s = fromMin(startKey);
    final e = toMin(endKey);
    if (s == null || e == null) return false;
    final cur = now.hour * 60 + now.minute;
    return cur >= s && cur <= e;
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.event,
    required this.times,
    required this.isNow,
  });

  final ScheduleEvent event;
  final Map<String, String> times;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    final range = periodRange(event.period);
    final startRaw = times[range.startKey] ?? AppConstants.defaultTimes[range.startKey] ?? '';
    final endRaw = times[range.endKey] ?? AppConstants.defaultTimes[range.endKey] ?? startRaw;
    final startT = startRaw.split('-').first;
    final endT = endRaw.split('-').last;
    final periodText = range.start == range.end
        ? periodLabel(range.startKey)
        : '${periodLabel(range.startKey)}–${periodLabel(range.endKey)}';

    return Container(
      decoration: BoxDecoration(
        color: isNow ? const Color(0xFF2A2920) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNow ? AppTheme.ink : AppTheme.line,
          width: isNow ? 1.4 : 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间轴
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  startT,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isNow ? Colors.white : AppTheme.ink,
                  ),
                ),
                Text(
                  endT,
                  style: TextStyle(
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isNow ? Colors.white60 : AppTheme.muted,
                  ),
                ),
                if (isNow) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '进行中',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, color: isNow ? Colors.white24 : AppTheme.line),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.course,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: isNow ? Colors.white : AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      text: periodText,
                      bg: isNow ? Colors.white12 : AppTheme.soft2,
                      fg: isNow ? Colors.white : AppTheme.ink,
                    ),
                    _Chip(
                      text: '${range.rowspan}节连上',
                      bg: isNow ? Colors.white12 : AppTheme.soft2,
                      fg: isNow ? Colors.white70 : AppTheme.muted,
                    ),
                    _Chip(
                      text: event.weekPattern,
                      bg: isNow ? Colors.white12 : AppTheme.tagWeekBg,
                      fg: isNow ? Colors.white70 : AppTheme.tagWeek,
                    ),
                  ],
                ),
                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _MetaRow(
                    icon: Icons.place_outlined,
                    text: event.location,
                    dim: isNow,
                  ),
                ],
                if (event.teacher.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.person_outline,
                    text: event.teacher,
                    dim: isNow,
                  ),
                ],
                if (event.className.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.groups_2_outlined,
                    text: event.className,
                    dim: isNow,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  weekRule(
                    weekStart: event.weekStart,
                    weekEnd: event.weekEnd,
                    weekPattern: event.weekPattern,
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: isNow ? Colors.white54 : AppTheme.faint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    required this.dim,
  });

  final IconData icon;
  final String text;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: dim ? Colors.white54 : AppTheme.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: dim ? Colors.white70 : AppTheme.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

/// 周内日期选择条
class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    required this.dates,
    required this.selected,
    required this.hasCourseOn,
    required this.onSelect,
  });

  final List<DateTime> dates;
  final DateTime selected;
  final bool Function(DateTime date) hasCourseOn;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return SizedBox(
      height: 68,
      child: Row(
        children: [
          for (var index = 0; index < dates.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Builder(builder: (context) {
              final date = dates[index];
              final isSel = sameDate(date, selected);
              final isToday = sameDate(date, today);
              final hasCourse = hasCourseOn(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSel ? AppTheme.ink : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel
                            ? AppTheme.ink
                            : isToday
                                ? AppTheme.lineStrong
                                : AppTheme.line,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppConstants.weekdays[index],
                          style: TextStyle(
                            fontSize: 11,
                            color: isSel ? Colors.white70 : AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSel ? Colors.white : AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasCourse
                                ? (isSel ? Colors.white : AppTheme.ink)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
