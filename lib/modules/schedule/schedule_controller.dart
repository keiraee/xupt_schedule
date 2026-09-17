import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/schedule_utils.dart';
import '../../data/school/schedule_db.dart';
import '../../data/school/school_client.dart';
import '../auth/auth_controller.dart';
import '../auth/login_page.dart';

class ScheduleController extends GetxController {
  ScheduleController(this.session);

  final SchoolSession session;

  final data = Rxn<ScheduleData>();
  final selectedMonday = startOfWeek(DateTime.now()).obs;
  final selectedDate = startOfDay(DateTime.now()).obs;
  final status = '正在同步课表…'.obs;
  final isError = false.obs;
  final termCode = ''.obs;
  final loading = false.obs;

  final _db = ScheduleDb.instance;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final cached = await _db.loadSchedule();
      final force = await _db.consumeForceRefresh();

      if (cached != null && !force) {
        data.value = cached;
        if (cached.studentId.isNotEmpty) {
          session.studentId.value = cached.studentId;
        }
        if (cached.studentName.isNotEmpty) {
          session.studentName.value = cached.studentName;
        }
        status.value = '已读本地库 · ${cached.events.length} 条课程';
        isError.value = false;
        return;
      }

      if (cached != null && force) {
        data.value = cached;
        status.value = '正在刷新课表…';
      }
    } catch (err) {
      status.value = '读本地库失败：$err';
    }
    await sync();
  }

  DateTime get monday => startOfWeek(selectedMonday.value);

  List<DateTime> get dates =>
      List.generate(7, (index) => addDays(monday, index));

  List<DateTime> get weekdayDates =>
      List.generate(AppConstants.weekdayCount, (index) => addDays(monday, index));

  List<ScheduleEvent> get weekendEvents {
    final items = <ScheduleEvent>[];
    for (final date in dates.skip(AppConstants.weekdayCount)) {
      items.addAll(eventsForDate(date));
    }
    return items;
  }

  String get termLabel => data.value?.selectedTermLabel ?? '';

  String get selectedTermCode {
    if (termCode.value.isNotEmpty) return termCode.value;
    return data.value?.selectedTermCode ?? '';
  }

  DateTime? get termStart => defaultTermStart(termLabel);

  int? get week => academicWeek(monday, termStart);

  bool get isCurrentWeek => sameDate(monday, startOfWeek(DateTime.now()));

  int get maxWeek => data.value?.maxWeek ?? 20;

  String get weekHeading {
    final current = week;
    if (current != null && current >= 1) return '第 $current 周';
    return isCurrentWeek ? '本周' : '所选周';
  }

  String get weekRangeLabel {
    return '${formatShortDate(monday)} — ${formatShortDate(addDays(monday, AppConstants.weekdayCount - 1))}';
  }

  String get weekStatus {
    final current = week;
    final start = termStart;
    if (current != null && current < 1 && start != null) {
      return '学期尚未开始 · 预计 ${formatShortDate(start)} 进入第 1 周';
    }
    if (current != null && current > 20) return '本学期教学周已经结束';
    if (current != null && start != null) {
      return '教学第 $current 周 · 第 1 周 ${formatShortDate(start)}';
    }
    return '等待学期日期信息';
  }

  void goPrevWeek() {
    final nextMonday = addDays(monday, -7);
    selectedMonday.value = nextMonday;
    selectedDate.value = nextMonday;
  }

  void goNextWeek() {
    final nextMonday = addDays(monday, 7);
    selectedMonday.value = nextMonday;
    selectedDate.value = nextMonday;
  }

  void backToToday() {
    final now = startOfWeek(DateTime.now());
    selectedMonday.value = now;
    selectedDate.value = startOfDay(DateTime.now());
  }

  void jumpToWeek(int next) {
    final start = termStart;
    if (start == null) return;
    final target = addDays(start, (next - 1) * 7);
    selectedMonday.value = target;
    selectedDate.value = target;
  }

  bool eventRunsOn(ScheduleEvent event, DateTime date) {
    final currentWeek = academicWeek(date, termStart);
    if (currentWeek == null ||
        date.weekday != event.weekdayIndex ||
        currentWeek < event.weekStart ||
        currentWeek > event.weekEnd) {
      return false;
    }
    if (event.weekPattern == '单周' && currentWeek.isEven) return false;
    if (event.weekPattern == '双周' && currentWeek.isOdd) return false;
    return true;
  }

  List<ScheduleEvent> eventsForDate(DateTime date) {
    final items = data.value?.events ?? const <ScheduleEvent>[];
    final list = items.where((event) => eventRunsOn(event, date)).toList();
    list.sort((a, b) {
      final ra = periodRange(a.period);
      final rb = periodRange(b.period);
      return ra.start.compareTo(rb.start);
    });
    return list;
  }

  Future<void> sync([String? nextTerm]) async {
    final term = nextTerm ?? termCode.value;
    loading.value = true;
    status.value = '正在同步课表…';
    isError.value = false;
    try {
      final client = session.requireClient();
      final parsed = await client.fetchSchedule(
        termCode: term,
        studentIdHint: session.studentId.value,
      );
      data.value = parsed;
      if (parsed.studentId.isNotEmpty) {
        session.studentId.value = parsed.studentId;
      }
      if (parsed.studentName.isNotEmpty) {
        session.studentName.value = parsed.studentName;
      }
      await _db.saveSchedule(parsed);
      await session.persistCookies();
      status.value = '已更新 · ${parsed.events.length} 条课程安排（已写入本地库）';
    } on SchoolException catch (err) {
      status.value = err.message;
      isError.value = true;
      if (err.isSessionExpired) await _forceLogout(clearCookies: true);
    } catch (err) {
      status.value = '$err';
      isError.value = true;
    } finally {
      loading.value = false;
    }
  }

  Future<void> changeTerm(String code) async {
    final previous = termCode.value;
    termCode.value = code;
    await sync(code);
    if (isError.value) termCode.value = previous;
  }

  Future<void> logout() async {
    await session.logout();
    await _forceLogout(clearCookies: false);
  }

  Future<void> _forceLogout({required bool clearCookies}) async {
    if (clearCookies) await session.invalidate();
    Get.offAllNamed(LoginPage.routeName);
  }

  List<Map<String, String>> get weekOptions {
    final start = termStart;
    if (start == null) return const [];
    final formatter = DateFormat('M/d');
    return List.generate(maxWeek, (index) {
      final weekNumber = index + 1;
      final rangeStart = addDays(start, index * 7);
      final rangeEnd = addDays(rangeStart, 6);
      return {
        'value': '$weekNumber',
        'label':
            '第 $weekNumber 周 · ${formatter.format(rangeStart)}—${formatter.format(rangeEnd)}',
      };
    });
  }
}
