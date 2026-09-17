import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme.dart';
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
      body: SafeArea(
        child: Obx(() {
          final scheduleData = controller.data.value;
          final statusText = controller.status.value;
          final error = controller.isError.value;
          final week = controller.week;
          final weekHeading = controller.weekHeading;
          final weekRange = controller.weekRangeLabel;
          final weekStatus = controller.weekStatus;
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
                if (scheduleData != null && scheduleData.terms.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Spacer(),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 176, minWidth: 128),
                          child: _PaperSelect(
                            text: _labelForTerm(scheduleData.terms, termCode),
                            onTap: () async {
                              final next = await showPaperOptions<String>(
                                context: context,
                                title: '选择学期',
                                selected: termCode,
                                options: [
                                  for (final term in scheduleData.terms)
                                    PaperOption(value: term.code, label: term.label),
                                ],
                              );
                              if (next != null) controller.changeTerm(next);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: _PaperSelect(
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
                _GhostButton(label: '今天', onTap: onToday),
              ],
            ),
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

String _labelForTerm(List<TermOption> terms, String selectedCode) {
  for (final term in terms) {
    if (term.code == selectedCode) return term.label;
  }
  return '学期';
}

class PaperOption<T> {
  const PaperOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _PaperSelect extends StatelessWidget {
  const _PaperSelect({
    required this.text,
    this.onTap,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.soft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 36,
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: enabled ? AppTheme.ink : AppTheme.faint,
                  ),
                ),
              ),
              Icon(
                Icons.expand_more,
                size: 18,
                color: enabled ? AppTheme.muted : AppTheme.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.lineStrong),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showPaperOptions<T>({
  required BuildContext context,
  required String title,
  required List<PaperOption<T>> options,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF6F5F1),
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) {
      final maxH = MediaQuery.of(context).size.height * 0.72;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final active = option.value == selected;
                      return Material(
                        color: active ? AppTheme.ink : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context, option.value),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? Colors.white
                                          : AppTheme.ink,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                if (active)
                                  const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
