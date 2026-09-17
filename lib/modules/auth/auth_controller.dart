import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/school/schedule_db.dart';
import '../../data/school/school_client.dart';
import '../shell/shell_page.dart';

class AuthController extends GetxController {
  AuthController();

  final username = ''.obs;
  final password = ''.obs;
  final smsCode = ''.obs;
  final loading = false.obs;
  final sendingSms = false.obs;
  final cooldown = 0.obs;
  final error = ''.obs;
  final hint = ''.obs;
  final mfaUsername = ''.obs;
  final mfaMethods = <AuthMethod>[].obs;
  final inMfa = false.obs;

  SchoolClient? _client;

  @override
  void onClose() {
    _client?.close();
    super.onClose();
  }

  void backToPassword() {
    inMfa.value = false;
    smsCode.value = '';
    error.value = '';
    hint.value = '';
    _client?.close();
    _client = null;
  }

  Future<void> submitPassword() async {
    final user = username.value.trim();
    final pass = password.value;
    if (user.isEmpty || pass.isEmpty) {
      error.value = '请输入学号和密码。';
      return;
    }
    loading.value = true;
    error.value = '';
    hint.value = '';
    _client?.close();
    final client = SchoolClient();
    _client = client;
    try {
      final result = await client.login(user, pass);
      await _persistAndGo(client, result);
    } on MfaRequiredException catch (mfa) {
      inMfa.value = true;
      mfaUsername.value = mfa.username;
      mfaMethods.assignAll(mfa.methods);
      hint.value = mfa.message;
    } on SchoolException catch (err) {
      error.value = err.message;
    } catch (err) {
      error.value = '$err';
    } finally {
      loading.value = false;
    }
  }

  Future<void> sendSms() async {
    if (!inMfa.value || cooldown.value > 0 || sendingSms.value) return;
    sendingSms.value = true;
    error.value = '';
    try {
      await _client?.sendMfaSms(mfaUsername.value);
      hint.value = '验证码已发送，请查收手机短信。';
      _startCooldown(60);
    } on SchoolException catch (err) {
      error.value = err.message;
    } catch (err) {
      error.value = '$err';
    } finally {
      sendingSms.value = false;
    }
  }

  Future<void> submitMfa() async {
    final client = _client;
    if (client == null) return;
    final code = smsCode.value.trim();
    if (code.isEmpty) {
      error.value = '请输入短信验证码。';
      return;
    }
    loading.value = true;
    error.value = '';
    try {
      final result = await client.completeMfaSms(mfaUsername.value, code);
      await _persistAndGo(client, result);
    } on SchoolException catch (err) {
      error.value = err.message;
    } catch (err) {
      error.value = '$err';
    } finally {
      loading.value = false;
    }
  }

  Future<void> _persistAndGo(SchoolClient client, LoginResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_id', result.studentId);
    await prefs.setString('student_name', result.studentName);
    await prefs.setString('school_cookies', jsonEncode(client.dump()));
    await ScheduleDb.instance.markForceRefresh();
    Get.find<SchoolSession>().adopt(client, result);
    inMfa.value = false;
    Get.offAllNamed(ShellPage.routeName);
  }

  void _startCooldown(int seconds) {
    cooldown.value = seconds;
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (cooldown.value <= 1) {
        cooldown.value = 0;
        return false;
      }
      cooldown.value -= 1;
      return true;
    });
  }
}

class SchoolSession extends GetxController {
  SchoolSession();

  final studentId = ''.obs;
  final studentName = ''.obs;
  SchoolClient? client;

  @override
  void onClose() {
    client?.close();
    super.onClose();
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    studentId.value = prefs.getString('student_id') ?? '';
    studentName.value = prefs.getString('student_name') ?? '';
    final raw = prefs.getString('school_cookies');
    if (raw == null || raw.isEmpty) return;
    try {
      final payload = jsonDecode(raw);
      if (payload is Map<String, dynamic>) {
        final restored = SchoolClient();
        restored.restore(payload);
        restored.rememberStudent(studentId.value, studentName.value);
        client = restored;
      }
    } catch (_) {}
  }

  void adopt(SchoolClient next, LoginResult result) {
    client?.close();
    client = next;
    studentId.value = result.studentId;
    studentName.value = result.studentName;
  }

  Future<void> persistCookies() async {
    final current = client;
    if (current == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('school_cookies', jsonEncode(current.dump()));
    if (studentId.value.isNotEmpty) {
      await prefs.setString('student_id', studentId.value);
    }
    if (studentName.value.isNotEmpty) {
      await prefs.setString('student_name', studentName.value);
    }
  }

  /// 学校会话失效：丢掉 Cookie，本地课表留下。
  Future<void> invalidate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('school_cookies');
    client?.close();
    client = null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('student_id');
    await prefs.remove('student_name');
    await prefs.remove('school_cookies');
    await ScheduleDb.instance.clearSchedule();
    client?.close();
    client = null;
    studentId.value = '';
    studentName.value = '';
  }

  SchoolClient requireClient() {
    final existing = client;
    if (existing != null) return existing;
    final created = SchoolClient();
    created.rememberStudent(studentId.value, studentName.value);
    client = created;
    return created;
  }
}
