import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

import 'school_models.dart';

final _scheduleRe = RegExp(
  r'(\d+)-(\d+)周\s*:\s*(连续周|单周|双周)\s+星期([一二三四五六日])\s+(.+?)节',
);

const _weekdays = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7};

class _Cell {
  _Cell(this.text, this.rowspan, this.colspan);

  String text;
  int rowspan;
  int colspan;
}

class _TableParser {
  List<List<_Cell>> grid1 = [];
  List<List<_Cell>> grid2 = [];
  List<TermOption> terms = [];
  Map<String, String> hidden = {};
  String formAction = '';
  String termSelectName = '';
}

_TableParser _readPage(String html) {
  final doc = html_parser.parse(html);
  final result = _TableParser();

  final form = doc.querySelector('form');
  if (form != null) {
    result.formAction = form.attributes['action'] ?? '';
  }
  for (final input in doc.querySelectorAll('input[type=hidden]')) {
    final name = input.attributes['name'];
    if (name != null && name.isNotEmpty) {
      result.hidden[name] = input.attributes['value'] ?? '';
    }
  }

  final termSelect = doc.querySelector('#MainWork_drpxq');
  if (termSelect != null) {
    result.termSelectName = termSelect.attributes['name'] ?? '';
    for (final option in termSelect.querySelectorAll('option')) {
      result.terms.add(TermOption(
        code: option.attributes['value'] ?? '',
        label: option.text.replaceAll(RegExp(r'\s+'), ' ').trim(),
        selected: option.attributes.containsKey('selected'),
      ));
    }
  }

  result.grid1 = _readTable(doc.getElementById('MainWork_DataGrid1'));
  result.grid2 = _readTable(doc.getElementById('MainWork_Datagrid2'));
  return result;
}

List<List<_Cell>> _readTable(dom.Element? table) {
  if (table == null) return [];
  final rows = <List<_Cell>>[];

  Iterable<dom.Element> rowNodes() {
    final tbody = table.children.cast<dom.Element?>().firstWhere(
          (el) => (el?.localName ?? '').toLowerCase() == 'tbody',
          orElse: () => null,
        );
    if (tbody != null) {
      return tbody.children.where((el) => (el.localName ?? '').toLowerCase() == 'tr');
    }
    return table.children.where((el) => (el.localName ?? '').toLowerCase() == 'tr');
  }

  for (final tr in rowNodes()) {
    final cells = <_Cell>[];
    for (final cell in tr.children) {
      final tag = cell.localName?.toLowerCase() ?? '';
      if (tag != 'td' && tag != 'th') continue;
      cells.add(_Cell(
        _cellText(cell),
        int.tryParse(cell.attributes['rowspan'] ?? '1') ?? 1,
        int.tryParse(cell.attributes['colspan'] ?? '1') ?? 1,
      ));
    }
    if (cells.isNotEmpty) rows.add(cells);
  }
  return rows;
}

String _cellText(dom.Element cell) {
  final buffer = StringBuffer();
  void walk(dom.Node node) {
    if (node is dom.Text) {
      buffer.write(node.text);
      return;
    }
    if (node is! dom.Element) return;
    final tag = node.localName?.toLowerCase() ?? '';
    if (tag == 'br') {
      buffer.write('\n');
      return;
    }
    for (final child in node.nodes) {
      walk(child);
    }
  }

  walk(cell);
  return buffer.toString().replaceAll('\xa0', ' ').trim();
}

List<List<(int, _Cell)>> _positionRows(List<List<_Cell>> rows) {
  final positioned = <List<(int, _Cell)>>[];
  final occupiedUntil = <int, int>{};
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    var column = 0;
    final current = <(int, _Cell)>[];
    for (final cell in rows[rowIndex]) {
      while ((occupiedUntil[column] ?? 0) > rowIndex) {
        column += 1;
      }
      current.add((column, cell));
      if (cell.rowspan > 1) {
        for (var offset = 0; offset < cell.colspan; offset++) {
          occupiedUntil[column + offset] = rowIndex + cell.rowspan;
        }
      }
      column += cell.colspan;
    }
    positioned.add(current);
  }
  return positioned;
}

String _lookup(List<String> block, String prefix) {
  for (final line in block) {
    if (line.startsWith(prefix)) {
      return line.substring(prefix.length).trim();
    }
  }
  return '';
}

List<ScheduleEvent> _courseEvents(String text, int column) {
  final lines = text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .toList();
  final starts = <int>[
    for (var i = 0; i < lines.length; i++)
      if (lines[i].startsWith('课程:')) i
  ];
  final events = <ScheduleEvent>[];
  for (var i = 0; i < starts.length; i++) {
    final start = starts[i];
    final end = i + 1 < starts.length ? starts[i + 1] : lines.length;
    final block = lines.sublist(start, end);
    final scheduleLine =
        block.cast<String?>().firstWhere((line) => _scheduleRe.hasMatch(line ?? ''), orElse: () => null);
    if (scheduleLine == null) continue;
    final match = _scheduleRe.firstMatch(scheduleLine)!;
    var location = '';
    for (final line in block) {
      if (line.startsWith('(') && line.endsWith(')') && line.length > 2) {
        location = line.substring(1, line.length - 1).trim();
        break;
      }
    }
    final weekday = match.group(4)!;
    events.add(ScheduleEvent(
      course: _lookup(block, '课程:'),
      className: _lookup(block, '班级:'),
      location: location,
      teacher: _lookup(block, '主讲教师:'),
      weekday: weekday,
      weekdayIndex: _weekdays[weekday] ?? 0,
      period: (match.group(5) ?? '').trim(),
      weekStart: int.parse(match.group(1)!),
      weekEnd: int.parse(match.group(2)!),
      weekPattern: match.group(3)!,
    ));
  }
  return events;
}

int _periodOrder(String period) {
  final first = period.split('-').first.trim();
  if (first == '中午1') return 5;
  if (first == '中午2') return 6;
  final n = int.tryParse(first);
  if (n == null) return 99;
  return n <= 4 ? n : n + 2;
}

ScheduleData parseScheduleHtml(String html) {
  final page = _readPage(html);
  if (page.grid1.isEmpty) {
    throw SchoolException('没有找到课表表格；页面可能是登录页，或登录会话已经失效。',
        code: 'session_expired');
  }

  final events = <ScheduleEvent>[];
  final positioned = _positionRows(page.grid1);
  for (var i = 1; i < positioned.length; i++) {
    for (final (column, cell) in positioned[i]) {
      if (column >= 2 && column <= 8 && cell.text.contains('课程:')) {
        events.addAll(_courseEvents(cell.text, column));
      }
    }
  }
  events.sort((a, b) {
    final c = a.weekdayIndex.compareTo(b.weekdayIndex);
    if (c != 0) return c;
    final p = _periodOrder(a.period).compareTo(_periodOrder(b.period));
    if (p != 0) return p;
    return a.weekStart.compareTo(b.weekStart);
  });

  final unscheduled = <UnscheduledItem>[];
  for (var i = 1; i < page.grid2.length; i++) {
    final values = page.grid2[i].map((cell) => cell.text.trim()).toList();
    if (values.every((value) => value.isEmpty)) continue;
    while (values.length < 5) {
      values.add('');
    }
    unscheduled.add(UnscheduledItem(
      className: values[0],
      course: values[1],
      teacher: values[2],
      location: values[3],
      time: values[4],
    ));
  }

  TermOption? selected;
  for (final term in page.terms) {
    if (term.selected) selected = term;
  }
  final studentMatch =
      RegExp(r'[?&]xh=(\d+)').firstMatch(page.formAction.replaceAll('&amp;', '&'));

  return ScheduleData(
    studentId: studentMatch?.group(1) ?? '',
    studentName: '',
    termCode: selected?.code ?? '',
    termLabel: selected?.label ?? '',
    terms: page.terms,
    events: events,
    unscheduled: unscheduled,
  );
}

WebformsState extractWebformsState(String html) {
  final page = _readPage(html);
  return WebformsState(
    hidden: page.hidden,
    terms: page.terms,
    termSelectName: page.termSelectName,
  );
}
