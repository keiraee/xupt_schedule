import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme.dart';
import '../../core/constants.dart';
import 'auth_controller.dart';

void _hideKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
}

class _TapToDismiss extends StatelessWidget {
  const _TapToDismiss({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideKeyboard,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  static const routeName = '/login';

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F1),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Obx(() {
          if (controller.inMfa.value) {
            return _MfaForm(
              controller: controller,
              keyboardOpen: keyboardOpen,
            );
          }
          return _PasswordForm(
            controller: controller,
            keyboardOpen: keyboardOpen,
          );
        }),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({
    required this.title,
    required this.subtitle,
  });

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
    required this.keyboardOpen,
    this.footer,
  });

  final Widget child;
  final bool keyboardOpen;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.fromLTRB(28, 24, 28, 20);
    return Padding(
      padding: padding,
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: keyboardOpen
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const _TapToDismiss(child: SizedBox.expand()),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (footer != null) _TapToDismiss(child: footer!),
        ],
      ),
    );
  }
}

class _PasswordForm extends StatefulWidget {
  const _PasswordForm({
    required this.controller,
    required this.keyboardOpen,
  });

  final AuthController controller;
  final bool keyboardOpen;

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final keyboardOpen = widget.keyboardOpen;
    return _CenteredShell(
      keyboardOpen: keyboardOpen,
      footer: const Text(
        '密码仅用于本次登录请求，不会保存。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.faint),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TapToDismiss(
            child: _BrandMark(
              title: '西邮课表',
              subtitle: '使用学校统一身份认证账号登录',
            ),
          ),
          const SizedBox(height: 28),
          TextFieldTapRegion(
            child: Column(
              children: [
                TextField(
                  focusNode: _usernameFocus,
                  onChanged: (value) => controller.username.value = value,
                  decoration: const InputDecoration(labelText: '学号'),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  scrollPadding: const EdgeInsets.only(bottom: 80),
                ),
                const SizedBox(height: 12),
                TextField(
                  focusNode: _passwordFocus,
                  onChanged: (value) => controller.password.value = value,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '密码'),
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  scrollPadding: const EdgeInsets.only(bottom: 80),
                  onSubmitted: (_) {
                    _hideKeyboard();
                    controller.submitPassword();
                  },
                ),
              ],
            ),
          ),
          Obx(() {
            final message = controller.error.value;
            if (message.isEmpty) return const SizedBox.shrink();
            return _Banner(message: message, color: AppTheme.danger);
          }),
          const SizedBox(height: 18),
          Obx(() {
            return FilledButton(
              onPressed: controller.loading.value
                  ? null
                  : () {
                      _hideKeyboard();
                      controller.submitPassword();
                    },
              child: Text(controller.loading.value ? '正在登录…' : '登录并进入课表'),
            );
          }),
        ],
      ),
    );
  }
}

class _MfaForm extends StatefulWidget {
  const _MfaForm({
    required this.controller,
    required this.keyboardOpen,
  });

  final AuthController controller;
  final bool keyboardOpen;

  @override
  State<_MfaForm> createState() => _MfaFormState();
}

class _MfaFormState extends State<_MfaForm> {
  final _codeFocus = FocusNode();

  @override
  void dispose() {
    _codeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final keyboardOpen = widget.keyboardOpen;
    return _CenteredShell(
      keyboardOpen: keyboardOpen,
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
            return _TapToDismiss(
              child: _BrandMark(
                title: '二次认证',
                subtitle:
                    '账号 ${controller.mfaUsername.value}\n可用方式：${methods.isEmpty ? '手机验证码' : methods}',
              ),
            );
          }),
          const SizedBox(height: 28),
          TextFieldTapRegion(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _codeFocus,
                    onChanged: (value) => controller.smsCode.value = value,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(labelText: '短信验证码'),
                    scrollPadding: const EdgeInsets.only(bottom: 80),
                    onSubmitted: (_) {
                      _hideKeyboard();
                      controller.submitMfa();
                    },
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
              onPressed: controller.loading.value
                  ? null
                  : () {
                      _hideKeyboard();
                      controller.submitMfa();
                    },
              child: Text(controller.loading.value ? '正在验证…' : '完成认证并进入课表'),
            );
          }),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              _hideKeyboard();
              controller.backToPassword();
            },
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
