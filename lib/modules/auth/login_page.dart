import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme.dart';
import '../../core/constants.dart';
import 'auth_controller.dart';

class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  static const routeName = '/login';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F1),
      body: SafeArea(
        child: Obx(() {
          if (controller.inMfa.value) {
            return _MfaForm(controller: controller);
          }
          return _PasswordForm(controller: controller);
        }),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          AppConstants.badgeAsset,
          width: 96,
          height: 96,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }
}

class _CenteredShell extends StatelessWidget {
  const _CenteredShell({
    required this.child,
    this.footer,
  });

  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
            child: footer,
          ),
      ],
    );
  }
}

class _PasswordForm extends StatelessWidget {
  const _PasswordForm({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return _CenteredShell(
      footer: const Text(
        '密码仅用于本次登录请求，不会保存。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.faint),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BrandMark(
            title: '西邮课表',
            subtitle: '使用学校统一身份认证账号登录',
          ),
          const SizedBox(height: 28),
          TextField(
            onChanged: (value) => controller.username.value = value,
            decoration: const InputDecoration(labelText: '用户名 / 学号'),
            keyboardType: TextInputType.text,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => controller.password.value = value,
            obscureText: true,
            decoration: const InputDecoration(labelText: '密码'),
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => controller.submitPassword(),
          ),
          Obx(() {
            final message = controller.error.value;
            if (message.isEmpty) return const SizedBox.shrink();
            return _Banner(message: message, color: AppTheme.danger);
          }),
          const SizedBox(height: 18),
          Obx(() {
            return FilledButton(
              onPressed: controller.loading.value ? null : controller.submitPassword,
              child: Text(controller.loading.value ? '正在登录…' : '登录并进入课表'),
            );
          }),
        ],
      ),
    );
  }
}

class _MfaForm extends StatelessWidget {
  const _MfaForm({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return _CenteredShell(
      footer: const Text(
        '验证码仅用于完成本次登录。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.faint),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final methods = controller.mfaMethods
                .map((item) => item.label)
                .where((label) => label.isNotEmpty)
                .join(' / ');
            return _BrandMark(
              title: '二次认证',
              subtitle:
                  '账号 ${controller.mfaUsername.value}\n可用方式：${methods.isEmpty ? '手机验证码' : methods}',
            );
          }),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => controller.smsCode.value = value,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '短信验证码'),
                ),
              ),
              const SizedBox(width: 10),
              Obx(() {
                final cool = controller.cooldown.value;
                final sending = controller.sendingSms.value;
                final label = cool > 0
                    ? '${cool}s'
                    : sending
                        ? '发送中…'
                        : '获取验证码';
                return SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: cool > 0 || sending ? null : controller.sendSms,
                    child: Text(label),
                  ),
                );
              }),
            ],
          ),
          Obx(() {
            final hint = controller.hint.value;
            if (hint.isEmpty) return const SizedBox.shrink();
            return _Banner(message: hint, color: AppTheme.accent);
          }),
          Obx(() {
            final message = controller.error.value;
            if (message.isEmpty) return const SizedBox.shrink();
            return _Banner(message: message, color: AppTheme.danger);
          }),
          const SizedBox(height: 18),
          Obx(() {
            return FilledButton(
              onPressed: controller.loading.value ? null : controller.submitMfa,
              child: Text(controller.loading.value ? '正在验证…' : '完成认证并进入课表'),
            );
          }),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: controller.backToPassword,
            child: const Text('返回重新登录'),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 13, height: 1.4),
      ),
    );
  }
}
