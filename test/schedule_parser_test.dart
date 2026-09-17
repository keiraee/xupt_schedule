import 'package:flutter_test/flutter_test.dart';
import 'package:xupt_schedule_app/core/schedule_utils.dart';
import 'package:xupt_schedule_app/data/school/schedule_parser.dart';

const _html = '''
<form action="./kbcx_xs.aspx?xh=2610321101">
  <select id="MainWork_drpxq" name="ctl00\$MainWork\$drpxq">
    <option value="55" selected>2026-2027（一）</option>
  </select>
  <table id="MainWork_DataGrid1">
    <tr><td></td><td>节次</td><td>星期一</td><td>星期二</td><td>星期三</td><td>星期四</td><td>星期五</td><td>星期六</td><td>星期日</td></tr>
    <tr>
      <td rowspan="5">上午</td><td>1</td><td></td><td></td>
      <td rowspan="2">课程:AI全栈开发实验（实践、校企）<br>班级:AI全栈开发实验（实践、校企）<br>()<br>3-18周:连续周  星期三 1-2节<br>主讲教师:李培<br><br></td>
      <td></td><td></td><td></td><td></td>
    </tr>
    <tr><td>2</td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
    <tr>
      <td>3</td><td></td><td></td><td></td>
      <td rowspan="2">课程:工程优化方法及应用（工程）<br>班级:工程优化方法及应用（工程）6<br>(雁塔B502)<br>3-18周:连续周  星期四 3-4节<br>主讲教师:常甜甜<br><br></td>
      <td></td><td></td><td></td>
    </tr>
    <tr><td>4</td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
    <tr><td>中午1</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
    <tr>
      <td rowspan="5">下午</td><td>中午2</td>
      <td rowspan="3">课程:工程伦理（混合）<br>班级:工程伦理（混合）6<br>(雁塔B502)<br>12-12周:连续周  星期一 中午2-6节<br>主讲教师:郭瑞<br><br>课程:工程伦理（混合）<br>班级:工程伦理（混合）6<br>(雁塔B502)<br>4-4周:连续周  星期一 中午2-6节<br>主讲教师:郭瑞<br><br></td>
      <td></td>
      <td rowspan="3">课程:新时代中国特色社会主义理论与实践研究<br>班级:思政10<br>(雁塔B502)<br>3-18周:双周  星期三 中午2-6节<br>主讲教师:王应春<br><br></td>
      <td rowspan="3">课程:高级计算机网络<br>班级:高级计算机网络<br>(雁塔A606)<br>3-18周:连续周  星期四 中午2-6节<br>主讲教师:谢晓燕<br><br></td>
      <td></td><td></td><td></td>
    </tr>
    <tr>
      <td>5</td><td></td>
      <td rowspan="2">课程:创新创业系列讲座（案例、校企）<br>班级:讲座2<br>(雁塔B401)<br>3-18周:双周  星期五 5-6节<br>主讲教师:屈军锁<br><br></td>
      <td></td><td></td>
    </tr>
    <tr><td>6</td><td></td><td></td><td></td></tr>
    <tr><td>7</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
    <tr><td>8</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
    <tr>
      <td rowspan="3">晚上</td><td>9</td>
      <td rowspan="3">课程:计算机科学中的数理逻辑<br>班级:数理逻辑<br>(雁塔A401)<br>3-18周:连续周  星期一 9-11节<br>主讲教师:陈彦萍<br><br></td>
      <td rowspan="3">课程:人工智能<br>班级:人工智能2<br>(雁塔A301)<br>3-18周:连续周  星期二 9-11节<br>主讲教师:李培<br><br></td>
      <td></td><td></td><td></td><td></td><td></td>
    </tr>
    <tr><td>10</td><td></td><td></td><td></td><td></td><td></td></tr>
    <tr><td>11</td><td></td><td></td><td></td><td></td><td></td></tr>
  </table>
  <table id="MainWork_Datagrid2">
    <tr><td>班级名称</td><td>课程名称</td><td>主讲教师</td><td>上课地点</td><td>上课时段</td></tr>
    <tr><td>学术活动</td><td>学术活动</td><td></td><td></td><td>尚未进行排课</td></tr>
  </table>
</form>
''';

void main() {
  test('parses school grid including 中午2-6 and empty location', () {
    final data = parseScheduleHtml(_html);
    expect(data.studentId, '2610321101');
    expect(data.termLabel, '2026-2027（一）');
    final names = data.events
        .map((e) => '${e.course}|${e.weekStart}-${e.weekEnd}|周${e.weekday}${e.period}')
        .toList();
    expect(names, [
      '工程伦理（混合）|4-4|周一中午2-6',
      '工程伦理（混合）|12-12|周一中午2-6',
      '计算机科学中的数理逻辑|3-18|周一9-11',
      '人工智能|3-18|周二9-11',
      'AI全栈开发实验（实践、校企）|3-18|周三1-2',
      '新时代中国特色社会主义理论与实践研究|3-18|周三中午2-6',
      '工程优化方法及应用（工程）|3-18|周四3-4',
      '高级计算机网络|3-18|周四中午2-6',
      '创新创业系列讲座（案例、校企）|3-18|周五5-6',
    ]);
    expect(data.unscheduled, hasLength(1));

    final ethic = data.events.where((e) => e.course.contains('工程伦理'));
    expect(ethic.length, 2);
    expect(ethic.every((e) => e.period == '中午2-6'), isTrue);
    expect(ethic.every((e) => e.weekdayIndex == 1), isTrue);

    final ai = data.events.firstWhere((e) => e.course.startsWith('AI'));
    expect(ai.location, isEmpty);
    expect(ai.weekdayIndex, 3);
    expect(ai.period, '1-2');

    // 中午2-6 覆盖 中午2、5、6 共 3 个节次行
    final ethicRange = periodRange('中午2-6');
    expect(ethicRange.startKey, '中午2');
    expect(ethicRange.endKey, '6');
    expect(ethicRange.rowspan, 3);
  });
}
