import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme.dart';
import '../../core/schedule_utils.dart';
import '../../data/school/school_client.dart';
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F5F1),
        titleSpacing: 16,
        title: Obx(() => Text(controller.pageTitle)),
        actions: [
          IconButton(
            tooltip: '退出登录',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('退出登录'),
                  content: const Text('确定退出当前账号吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('退出'),
                    ),
                  ],
                ),
              );
              if (ok == true) await controller.logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final scheduleData = controller.data.value;
          final loading = controller.loading.value;
          final statusText = controller.status.value;
          final error = controller.isError.value;
          final week = controller.week;
          final weekHeading = controller.weekHeading;
          final weekRange = controller.weekRangeLabel;
          final weekStatus = controller.weekStatus;
          final studentName = controller.studentName;
          final studentId = controller.studentId;
          final termCode = controller.selectedTermCode;
          final weekOptions = controller.weekOptions;
          final maxWeek = controller.maxWeek;
          final dayDates = controller.weekdayDates;
          final weekendEvents = controller.weekendEvents;
          // 触发依赖
          controller.selectedDate.value;
          controller.selectedMonday.value;
          controller.data.value;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  name: studentName,
                  studentId: studentId,
                  terms: scheduleData?.terms ?? const [],
                  selectedCode: termCode,
                  onChangeTerm: controller.changeTerm,
                ),
                const SizedBox(height: 8),
                _WeekNav(
                  weekHeading: weekHeading,
                  weekRangeLabel: weekRange,
                  week: week,
                  weekOptions: weekOptions,
                  maxWeek: maxWeek,
                  loading: loading,
                  onPrev: controller.goPrevWeek,
                  onNext: controller.goNextWeek,
                  onJump: controller.jumpToWeek,
                  onToday: controller.backToToday,
                  onRefresh: () => controller.sync(),
                ),
                const SizedBox(height: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: error ? AppTheme.danger : AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weekStatus,
                  style: const TextStyle(fontSize: 10, color: AppTheme.faint),
                ),
                const SizedBox(height: 8),
                if (scheduleData == null)
                  _BodyPlaceholder(
                    error: error,
                    onReload: () => controller.sync(),
                  )
                else ...[
                  WeekTimetable(
                    dates: dayDates,
                    eventsForDate: controller.eventsForDate,
                  ),
                  if (weekendEvents.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '本周周末还有 ${weekendEvents.length} 门课，未画进网格。',
                      style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                    ),
                  ],
                  const SizedBox(height: 10),
                  UnscheduledList(items: scheduleData.unscheduled),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.name,
    required this.studentId,
    required this.terms,
    required this.selectedCode,
    required this.onChangeTerm,
  });

  final String name;
  final String studentId;
  final List<TermOption> terms;
  final String selectedCode;
  final ValueChanged<String> onChangeTerm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name.isEmpty ? maskStudentId(studentId) : name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
        ),
        if (terms.isNotEmpty)
          SizedBox(
            width: 150,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.line),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  isExpanded: true,
                  value: selectedCode.isNotEmpty &&
                          terms.any((t) => t.code == selectedCode)
                      ? selectedCode
                      : null,
                  hint: const Text('学期', style: TextStyle(fontSize: 12)),
                  items: terms
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.code,
                          child: Text(
                            t.label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onChangeTerm(v);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekNav extends StatelessWidget {
  const _WeekNav({
    required this.weekHeading,
    required this.weekRangeLabel,
    required this.week,
    required this.weekOptions,
    required this.maxWeek,
    required this.loading,
    required this.onPrev,
    required this.onNext,
    required this.onJump,
    required this.onToday,
    required this.onRefresh,
  });

  final String weekHeading;
  final String weekRangeLabel;
  final int? week;
  final List<Map<String, String>> weekOptions;
  final int maxWeek;
  final bool loading;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onJump;
  final VoidCallback onToday;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
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
                    Text(
                      weekRangeLabel,
                      style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Builder(builder: (context) {
                  final w = week;
                  final ok = w != null && w >= 1 && w <= maxWeek && weekOptions.isNotEmpty;
                  return Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.soft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isDense: true,
                        isExpanded: true,
                        value: ok ? '$w' : null,
                        hint: const Text('跳周', style: TextStyle(fontSize: 12)),
                        items: weekOptions
                            .map(
                              (o) => DropdownMenuItem(
                                value: o['value'],
                                child: Text(
                                  o['label']!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: weekOptions.isEmpty
                            ? null
                            : (v) {
                                final n = int.tryParse(v ?? '');
                                if (n != null) onJump(n);
                              },
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: onToday,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('今天', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: loading ? null : onRefresh,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(loading ? '…' : '刷新', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyPlaceholder extends StatelessWidget {
  const _BodyPlaceholder({required this.error, required this.onReload});

  final bool error;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    if (error) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, size: 36, color: AppTheme.faint),
            const SizedBox(height: 10),
            const Text(
              '课表还没加载出来',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: onReload, child: const Text('重新加载')),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
