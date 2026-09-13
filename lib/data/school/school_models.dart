class SchoolException implements Exception {
  SchoolException(this.message, {this.code = 'school_error'});

  final String message;
  final String code;

  bool get isSessionExpired => code == 'session_expired';

  @override
  String toString() => message;
}

class MfaRequiredException implements Exception {
  MfaRequiredException({
    required this.username,
    required this.methods,
    required this.message,
  });

  final String username;
  final List<AuthMethod> methods;
  final String message;

  @override
  String toString() => message;
}

class AuthMethod {
  const AuthMethod({required this.authType, required this.label});

  final String authType;
  final String label;
}

class LoginResult {
  LoginResult({required this.studentId, required this.studentName});

  final String studentId;
  final String studentName;
}

class TermOption {
  TermOption({required this.code, required this.label, this.selected = false});

  final String code;
  final String label;
  final bool selected;

  Map<String, dynamic> toJson() => {
        'code': code,
        'label': label,
        'selected': selected,
      };

  factory TermOption.fromJson(Map<String, dynamic> json) => TermOption(
        code: json['code']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        selected: json['selected'] == true,
      );
}

class ScheduleEvent {
  ScheduleEvent({
    required this.course,
    this.teacher = '',
    this.location = '',
    this.className = '',
    required this.weekday,
    required this.weekdayIndex,
    required this.period,
    required this.weekStart,
    required this.weekEnd,
    required this.weekPattern,
  });

  final String course;
  final String teacher;
  final String location;
  final String className;
  final String weekday;
  final int weekdayIndex;
  final String period;
  final int weekStart;
  final int weekEnd;
  final String weekPattern;

  Map<String, dynamic> toJson() => {
        'course': course,
        'teacher': teacher,
        'location': location,
        'class_name': className,
        'weekday': weekday,
        'weekday_index': weekdayIndex,
        'period': period,
        'week_start': weekStart,
        'week_end': weekEnd,
        'week_pattern': weekPattern,
      };

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) => ScheduleEvent(
        course: json['course']?.toString() ?? '',
        teacher: json['teacher']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        className: json['class_name']?.toString() ?? '',
        weekday: json['weekday']?.toString() ?? '',
        weekdayIndex: int.tryParse('${json['weekday_index']}') ?? 0,
        period: json['period']?.toString() ?? '',
        weekStart: int.tryParse('${json['week_start']}') ?? 0,
        weekEnd: int.tryParse('${json['week_end']}') ?? 0,
        weekPattern: json['week_pattern']?.toString() ?? '',
      );
}

class UnscheduledItem {
  UnscheduledItem({
    required this.course,
    required this.time,
    this.teacher = '',
    this.location = '',
    this.className = '',
  });

  final String course;
  final String time;
  final String teacher;
  final String location;
  final String className;

  Map<String, dynamic> toJson() => {
        'course': course,
        'time': time,
        'teacher': teacher,
        'location': location,
        'class_name': className,
      };

  factory UnscheduledItem.fromJson(Map<String, dynamic> json) =>
      UnscheduledItem(
        course: json['course']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        teacher: json['teacher']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        className: json['class_name']?.toString() ?? '',
      );
}

class ScheduleData {
  ScheduleData({
    this.studentId = '',
    this.studentName = '',
    this.termCode = '',
    this.termLabel = '',
    this.terms = const [],
    this.events = const [],
    this.unscheduled = const [],
  });

  String studentId;
  String studentName;
  String termCode;
  String termLabel;
  List<TermOption> terms;
  List<ScheduleEvent> events;
  List<UnscheduledItem> unscheduled;

  String get selectedTermCode {
    if (termCode.isNotEmpty) return termCode;
    for (final term in terms) {
      if (term.selected) return term.code;
    }
    return '';
  }

  String get selectedTermLabel {
    if (termLabel.isNotEmpty) return termLabel;
    final code = selectedTermCode;
    for (final term in terms) {
      if (term.code == code) return term.label;
    }
    return '';
  }

  int get maxWeek {
    var max = 20;
    for (final event in events) {
      if (event.weekEnd > max) max = event.weekEnd;
    }
    return max;
  }

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'student_name': studentName,
        'term_code': termCode,
        'term_label': termLabel,
        'terms': terms.map((t) => t.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'unscheduled': unscheduled.map((u) => u.toJson()).toList(),
      };

  factory ScheduleData.fromJson(Map<String, dynamic> json) => ScheduleData(
        studentId: json['student_id']?.toString() ?? '',
        studentName: json['student_name']?.toString() ?? '',
        termCode: json['term_code']?.toString() ?? '',
        termLabel: json['term_label']?.toString() ?? '',
        terms: ((json['terms'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => TermOption.fromJson(e.cast<String, dynamic>()))
            .toList(),
        events: ((json['events'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => ScheduleEvent.fromJson(e.cast<String, dynamic>()))
            .toList(),
        unscheduled: ((json['unscheduled'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => UnscheduledItem.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

class WebformsState {
  WebformsState({
    this.hidden = const {},
    this.terms = const [],
    this.termSelectName = '',
  });

  final Map<String, String> hidden;
  final List<TermOption> terms;
  final String termSelectName;

  TermOption? get selectedTerm {
    for (final term in terms) {
      if (term.selected) return term;
    }
    return null;
  }
}
