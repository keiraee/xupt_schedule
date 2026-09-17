import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/theme.dart';
import 'core/constants.dart';
import 'modules/auth/auth_binding.dart';
import 'modules/auth/auth_controller.dart';
import 'modules/auth/login_page.dart';
import 'modules/shell/shell_binding.dart';
import 'modules/shell/shell_page.dart';

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

class XuptScheduleApp extends StatefulWidget {
  const XuptScheduleApp({super.key, required this.startOnSchedule});

  final bool startOnSchedule;

  @override
  State<XuptScheduleApp> createState() => _XuptScheduleAppState();
}

class _XuptScheduleAppState extends State<XuptScheduleApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDisclaimerIfNeeded(_navigatorKey.currentContext);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialBinding: widget.startOnSchedule ? ShellBinding() : AuthBinding(),
      initialRoute:
          widget.startOnSchedule ? ShellPage.routeName : LoginPage.routeName,
      getPages: [
        GetPage(
          name: LoginPage.routeName,
          page: () => const LoginPage(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: ShellPage.routeName,
          page: () => const ShellPage(),
          binding: ShellBinding(),
        ),
      ],
    );
  }
}

Future<void> showDisclaimerIfNeeded(BuildContext? context) async {
  if (context == null || !context.mounted) return;
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return;
  if (prefs.getBool(AppConstants.prefsDisclaimerAcked) == true) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            '使用说明',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink),
          ),
          content: const Text(
            '本软件仅为方便查看课表、学习相关技术而作。作者不承担任何法律责任。\n\n点击「已知晓」即表示你已阅读并同意以上说明。',
            style: TextStyle(fontSize: 14, height: 1.55, color: AppTheme.ink),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                await prefs.setBool(AppConstants.prefsDisclaimerAcked, true);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('已知晓'),
            ),
          ],
        ),
      );
    },
  );
}
