import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/theme.dart';
import 'core/constants.dart';
import 'modules/auth/auth_binding.dart';
import 'modules/auth/auth_controller.dart';
import 'modules/auth/login_page.dart';
import 'modules/schedule/schedule_binding.dart';
import 'modules/schedule/schedule_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs, permanent: true);

  final session = SchoolSession();
  await session.restore();
  Get.put<SchoolSession>(session, permanent: true);

  final loggedIn = session.studentId.isNotEmpty && session.client != null;

  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            '界面出错了\n${details.exception}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF9B3D36), fontSize: 13),
          ),
        ),
      ),
    );
  };

  runApp(XuptScheduleApp(startOnSchedule: loggedIn));
}

class XuptScheduleApp extends StatelessWidget {
  const XuptScheduleApp({super.key, required this.startOnSchedule});

  final bool startOnSchedule;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialBinding: startOnSchedule ? ScheduleBinding() : AuthBinding(),
      initialRoute: startOnSchedule ? SchedulePage.routeName : LoginPage.routeName,
      getPages: [
        GetPage(
          name: LoginPage.routeName,
          page: () => const LoginPage(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: SchedulePage.routeName,
          page: () => const SchedulePage(),
          binding: ScheduleBinding(),
        ),
      ],
    );
  }
}
