import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/constants.dart';
import '../../core/schedule_utils.dart';
import '../../data/school/school_client.dart';
import '../schedule/schedule_controller.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, this.onGoSchedule});

  static const routeName = '/today';

  /// 点击"查看完整课表"时回调，由 ShellPage 传入切换 tab 的逻辑。
  final VoidCallback? onGoSchedule;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ScheduleController>();
    final now = DateTime.now();
    final today = startOfDay(now);
    final weekdayIndex = now.weekday; // 1=Mon .. 7=Sun

    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F1),
      body: SafeArea(
        child: Obx(() {
          final scheduleData = controller.data.value;
          final statusText = controller.status.value;
          final error = controller.isError.value;
          final week = controller.week;
          // 触发依赖
          controller.selectedDate.value;

          final events = controller.eventsForDate(today);
          final isWeekend = weekdayIndex > 5;

          return Column(
            children: [
              // ── 顶部日期卡片 ──
              _DateHeader(
                date: now,
                weekdayIndex: weekdayIndex,
                week: week,
                courseCount: events.length,
                isWeekend: isWeekend,
              ),
              // ── 课程列表 ──
              Expanded(
                child: scheduleData == null
                    ? _Placeholder(error: error, onReload: () => controller.sync())
                    : events.isEmpty
                        ? _EmptyState(
                            isWeekend: isWeekend,
                            onGoSchedule: onGoSchedule,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              return _TodayCourseCard(
                                event: events[index],
                                index: index,
                              );
                            },
                          ),
              ),
              // 底部状态
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: error ? AppTheme.danger : AppTheme.faint,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 日期头部
// ═══════════════════════════════════════════════════════

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.date,
    required this.weekdayIndex,
    required this.week,
    required this.courseCount,
    required this.isWeekend,
  });

  final DateTime date;
  final int weekdayIndex;
  final int? week;
  final int courseCount;
  final bool isWeekend;

  @override
  Widget build(BuildContext context) {
    final weekdayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdayNames[weekdayIndex];
    final monthNames = [
      '', '一月', '二月', '三月', '四月', '五月', '六月',
      '七月', '八月', '九月', '十月', '十一月', '十二月',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.line, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 左侧大日期
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.day}',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${monthNames[date.month]} · $weekday',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 右侧信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (week != null && week! >= 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.ink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '第 $week 周',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                isWeekend ? '今天是周末' : '$courseCount 节课',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: courseCount > 0 ? AppTheme.ink : AppTheme.faint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 课程卡片
// ═══════════════════════════════════════════════════════

class _TodayCourseCard extends StatelessWidget {
  const _TodayCourseCard({required this.event, required this.index});

  final ScheduleEvent event;
  final int index;

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
    final range = periodRange(event.period);
    final timeLabel = periodTimeRange(
      period: event.period,
      periodTimes: AppConstants.defaultTimes,
    );
    final bg = _palette[event.course.hashCode.abs() % _palette.length];
    final periodLabel = range.start == range.end
        ? '第${AppConstants.periods[range.start]}节'
        : '${AppConstants.periods[range.start]}-${AppConstants.periods[range.end]}节';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: () => _showDetail(context),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 左侧色条 + 节次
                  Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          periodLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeLabel.split('·').last.trim(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.muted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // 右侧内容
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.course,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.ink,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (event.location.isNotEmpty)
                            _InfoRow(
                              icon: Icons.place_outlined,
                              text: event.location,
                            ),
                          if (event.teacher.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _InfoRow(
                              icon: Icons.person_outline,
                              text: event.teacher,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.faint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.muted,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

// ═══════════════════════════════════════════════════════
// 空状态
// ═══════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isWeekend, this.onGoSchedule});

  final bool isWeekend;
  final VoidCallback? onGoSchedule;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isWeekend ? Icons.weekend_outlined : Icons.free_breakfast_outlined,
              size: 52,
              color: AppTheme.lineStrong,
            ),
            const SizedBox(height: 16),
            Text(
              isWeekend ? '今天是周末，好好休息' : '今天没有课',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isWeekend ? '可以去总课表看看本周安排' : '享受自由的一天吧',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.muted,
              ),
            ),
            if (onGoSchedule != null) ...[
              const SizedBox(height: 20),
              GhostButton(
                label: '查看完整课表',
                onTap: () => onGoSchedule?.call(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 加载占位
// ═══════════════════════════════════════════════════════

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.error, required this.onReload});

  final bool error;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    if (error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 40, color: AppTheme.faint),
              const SizedBox(height: 12),
              const Text(
                '课表还没加载出来',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onReload,
                child: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
