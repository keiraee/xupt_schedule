import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../about/about_page.dart';
import '../schedule/schedule_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  static const routeName = '/';

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F1),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _index == 0
            ? const SchedulePage(key: ValueKey(0))
            : const AboutPage(key: ValueKey(1)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.soft2,
        height: 62,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
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
