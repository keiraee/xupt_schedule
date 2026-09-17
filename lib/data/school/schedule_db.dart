import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'school_models.dart';

/// 课表 SQLite 本地库：解析结果落库，进 App 优先读库。
class ScheduleDb {
  ScheduleDb._();

  static final ScheduleDb instance = ScheduleDb._();

  static const _dbName = 'xupt_schedule.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;
    final path = p.join(await getDatabasesPath(), _dbName);
    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
    _db = db;
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE meta(
        id INTEGER PRIMARY KEY CHECK(id = 1),
        student_id TEXT NOT NULL DEFAULT '',
        student_name TEXT NOT NULL DEFAULT '',
        term_code TEXT NOT NULL DEFAULT '',
        term_label TEXT NOT NULL DEFAULT '',
        saved_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE terms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        label TEXT NOT NULL,
        selected INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course TEXT NOT NULL,
        teacher TEXT NOT NULL DEFAULT '',
        location TEXT NOT NULL DEFAULT '',
        class_name TEXT NOT NULL DEFAULT '',
        weekday TEXT NOT NULL,
        weekday_index INTEGER NOT NULL,
        period TEXT NOT NULL,
        week_start INTEGER NOT NULL,
        week_end INTEGER NOT NULL,
        week_pattern TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE unscheduled(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course TEXT NOT NULL,
        time TEXT NOT NULL DEFAULT '',
        teacher TEXT NOT NULL DEFAULT '',
        location TEXT NOT NULL DEFAULT '',
        class_name TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE flags(
        key TEXT PRIMARY KEY,
        value INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// 整表替换写入课表（事务）。
  Future<void> saveSchedule(ScheduleData data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('terms');
      await txn.delete('events');
      await txn.delete('unscheduled');
      await txn.delete('meta');

      await txn.insert('meta', {
        'id': 1,
        'student_id': data.studentId,
        'student_name': data.studentName,
        'term_code': data.termCode,
        'term_label': data.termLabel,
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      });

      final batch = txn.batch();
      for (final t in data.terms) {
        batch.insert('terms', {
          'code': t.code,
          'label': t.label,
          'selected': t.selected ? 1 : 0,
        });
      }
      for (final e in data.events) {
        batch.insert('events', {
          'course': e.course,
          'teacher': e.teacher,
          'location': e.location,
          'class_name': e.className,
          'weekday': e.weekday,
          'weekday_index': e.weekdayIndex,
          'period': e.period,
          'week_start': e.weekStart,
          'week_end': e.weekEnd,
          'week_pattern': e.weekPattern,
        });
      }
      for (final u in data.unscheduled) {
        batch.insert('unscheduled', {
          'course': u.course,
          'time': u.time,
          'teacher': u.teacher,
          'location': u.location,
          'class_name': u.className,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  Future<ScheduleData?> loadSchedule() async {
    final db = await database;
    final metaRows = await db.query('meta', limit: 1);
    if (metaRows.isEmpty) return null;
    final meta = metaRows.first;

    final termRows = await db.query('terms', orderBy: 'id ASC');
    final eventRows = await db.query('events', orderBy: 'id ASC');
    final unscheduledRows = await db.query('unscheduled', orderBy: 'id ASC');

    return ScheduleData(
      studentId: meta['student_id'] as String? ?? '',
      studentName: meta['student_name'] as String? ?? '',
      termCode: meta['term_code'] as String? ?? '',
      termLabel: meta['term_label'] as String? ?? '',
      terms: termRows
          .map(
            (r) => TermOption(
              code: r['code'] as String? ?? '',
              label: r['label'] as String? ?? '',
              selected: (r['selected'] as int? ?? 0) == 1,
            ),
          )
          .toList(),
      events: eventRows
          .map(
            (r) => ScheduleEvent(
              course: r['course'] as String? ?? '',
              teacher: r['teacher'] as String? ?? '',
              location: r['location'] as String? ?? '',
              className: r['class_name'] as String? ?? '',
              weekday: r['weekday'] as String? ?? '',
              weekdayIndex: r['weekday_index'] as int? ?? 0,
              period: r['period'] as String? ?? '',
              weekStart: r['week_start'] as int? ?? 0,
              weekEnd: r['week_end'] as int? ?? 0,
              weekPattern: r['week_pattern'] as String? ?? '',
            ),
          )
          .toList(),
      unscheduled: unscheduledRows
          .map(
            (r) => UnscheduledItem(
              course: r['course'] as String? ?? '',
              time: r['time'] as String? ?? '',
              teacher: r['teacher'] as String? ?? '',
              location: r['location'] as String? ?? '',
              className: r['class_name'] as String? ?? '',
            ),
          )
          .toList(),
    );
  }

  Future<void> clearSchedule() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('terms');
      await txn.delete('events');
      await txn.delete('unscheduled');
      await txn.delete('meta');
    });
  }

  Future<void> markForceRefresh() async {
    final db = await database;
    await db.insert(
      'flags',
      {'key': 'force_refresh', 'value': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> consumeForceRefresh() async {
    final db = await database;
    final rows = await db.query(
      'flags',
      where: 'key = ?',
      whereArgs: ['force_refresh'],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    await db.delete('flags', where: 'key = ?', whereArgs: ['force_refresh']);
    return (rows.first['value'] as int? ?? 0) != 0;
  }
}
