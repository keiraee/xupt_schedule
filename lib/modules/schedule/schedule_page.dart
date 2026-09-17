import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import 'schedule_controller.dart';
import 'widgets/unscheduled_list.dart';
import 'widgets/week_timetable.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  static const routeName = '/schedule';

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ScheduleController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F1),
      body: SafeArea(
        child: Obx(() {
          final scheduleData = controller.data.value;
          final statusText = controller.status.value;
          final error = controller.isError.value;
          final week = controller.week;
          final weekHeading = controller.weekHeading;
          final weekRange = controller.weekRangeLabel;
          final weekStatus = controller.weekStatus;
          final weekOptions = controller.weekOptions;
          final maxWeek = controller.maxWeek;
          final dayDates = controller.weekdayDates;
          final weekendEvents = controller.weekendEvents;
          // 触发依赖
          controller.selectedDate.value;
          controller.selectedMonday.value;
          controller.data.value;

          return Column(
            children: [
              // 周导航 + 状态
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.line, width: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    _WeekNav(
                      weekHeading: weekHeading,
                      weekRangeLabel: weekRange,
                      week: week,
                      weekOptions: weekOptions,
                      maxWeek: maxWeek,
                      onPrev: controller.goPrevWeek,
                      onNext: controller.goNextWeek,
                      onJump: controller.jumpToWeek,
                      onToday: controller.backToToday,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            weekStatus,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.faint,
                            ),
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            color: error ? AppTheme.danger : AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 课表主体
              Expanded(
                child: scheduleData == null
                    ? _BodyPlaceholder(
                        error: error,
                        onReload: () => controller.sync(),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                        children: [
                          WeekTimetable(
                            dates: dayDates,
                            eventsForDate: controller.eventsForDate,
                          ),
                          if (weekendEvents.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              '周末还有 ${weekendEvents.length} 门课',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.faint,
                              ),
                            ),
                          ],
                          if (scheduleData.unscheduled.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            UnscheduledList(items: scheduleData.unscheduled),
                          ],
                        ],
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── 周导航 ──

class _WeekNav extends StatelessWidget {
  const _WeekNav({
    required this.weekHeading,
    required this.weekRangeLabel,
    required this.week,
    required this.weekOptions,
    required this.maxWeek,
    required this.onPrev,
    required this.onNext,
    required this.onJump,
    required this.onToday,
  });

  final String weekHeading;
  final String weekRangeLabel;
  final int? week;
  final List<Map<String, String>> weekOptions;
  final int maxWeek;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onJump;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 左箭头 · 周标题 · 右箭头
        Row(
          children: [
            IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left, size: 22),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    weekHeading,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    weekRangeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right, size: 22),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 跳周选择器 + 今天按钮
        Row(
          children: [
            Expanded(
              child: PaperSelect(
                text: () {
                  final current = week;
                  return current != null && current >= 1
                      ? '第 $current 周'
                      : '跳周';
                }(),
                enabled: weekOptions.isNotEmpty,
                onTap: weekOptions.isEmpty
                    ? null
                    : () async {
                        final current = week;
                        final next = await showPaperOptions<int>(
                          context: context,
                          title: '跳到指定周',
                          selected: current != null &&
                                  current >= 1 &&
                                  current <= maxWeek
                              ? current
                              : null,
                          options: [
                            for (final option in weekOptions)
                              PaperOption(
                                value: int.parse(option['value']!),
                                label: option['label']!,
                              ),
                          ],
                        );
                        if (next != null) onJump(next);
                      },
              ),
            ),
            const SizedBox(width: 8),
            GhostButton(label: '今天', onTap: onToday),
          ],
        ),
      ],
    );
  }
}

// ── 加载占位 ──

class _BodyPlaceholder extends StatelessWidget {
  const _BodyPlaceholder({required this.error, required this.onReload});

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
