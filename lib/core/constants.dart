class AppConstants {
  AppConstants._();

  static const appName = '西邮课表';
  static const appVersion = '1.1.0';
  static const badgeAsset = 'assets/images/xupt_badge.png';
  static const prefsDisclaimerAcked = 'disclaimer_acked';

  static const repoOwner = 'keiraee';
  static const repoName = 'xupt_schedule';
  static const repoUrl = 'https://github.com/$repoOwner/$repoName';
  static const releasesApi =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  static const prefsSessionCookie = 'school_cookies';
  static const prefsStudentId = 'student_id';
  static const prefsStudentName = 'student_name';

  static const knownTermStarts = <String, String>{
    '2025-2026（二）': '2026-03-02',
  };

  static const weekdays = <String>['一', '二', '三', '四', '五', '六', '日'];
  static const weekdayCount = 5;

  static const periods = <String>[
    '1',
    '2',
    '3',
    '4',
    '中午1',
    '中午2',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
  ];

  /// 与研究生院课表一致：上午含中午1，下午从中午2起。
  static const sectionBreaks = <int, String>{
    0: '上午',
    5: '下午',
    10: '晚上',
  };

  static const defaultTimes = <String, String>{
    '1': '08:00-08:50',
    '2': '08:55-09:45',
    '3': '10:15-11:05',
    '4': '11:10-12:00',
    '中午1': '12:05-12:55',
    '中午2': '13:35-14:25',
    '5': '14:30-15:20',
    '6': '15:25-16:15',
    '7': '16:35-17:25',
    '8': '17:30-18:20',
    '9': '19:00-19:50',
    '10': '19:55-20:45',
    '11': '20:50-21:40',
  };
}
