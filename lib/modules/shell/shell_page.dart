import 'package:flutter/material.dart';

import '../about/about_page.dart';
import '../schedule/schedule_page.dart';
import '../today/today_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  static const routeName = '/shell';

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;

  void _goSchedule() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _index == 0
            ? TodayPage(key: const ValueKey(0), onGoSchedule: _goSchedule)
            : _index == 1
                ? const SchedulePage(key: ValueKey(1))
                : const AboutPage(key: ValueKey(2)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0x0A26251E),
        height: 62,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '今日',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: '课表',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: '关于',
          ),
        ],
      ),
    );
  }
}
