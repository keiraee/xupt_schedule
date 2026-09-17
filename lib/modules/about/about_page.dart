import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/constants.dart';
import '../../data/school/school_client.dart';
import '../auth/auth_controller.dart';
import '../schedule/schedule_controller.dart';
import 'update_service.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  bool _checking = false;
  UpdateResult? _updateAvailable;

  Future<void> _checkUpdate() async {
    setState(() {
      _checking = true;
      _updateAvailable = null;
    });
    final result = await UpdateService().check();
    if (!mounted) return;
    setState(() => _checking = false);

    if (result.isError) {
      _snack(result.error);
    } else if (result.hasUpdate) {
      setState(() => _updateAvailable = result);
      _snack('发现新版本 v${result.latestVersion}');
    } else {
      _snack('当前已是最新版本');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F1),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            _buildTermCard(),
            const SizedBox(height: 12),
            _buildUpdateCard(),
            const SizedBox(height: 12),
            _buildLinkCard(),
            const SizedBox(height: 28),
            const Text(
              '作者：keiraee',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.faint),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('退出登录'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 头部 ──

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          AppConstants.badgeAsset,
          width: 64,
          height: 64,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 12),
        Text(
          AppConstants.appName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'v${AppConstants.appVersion}',
          style: const TextStyle(fontSize: 12, color: AppTheme.muted),
        ),
        const SizedBox(height: 4),
        const Text(
          '西安邮电大学课表客户端',
          style: TextStyle(fontSize: 13, color: AppTheme.faint),
        ),
      ],
    );
  }

  // ── 学期选择 ──

  Widget _buildTermCard() {
    final controller = Get.find<ScheduleController>();
    return Obx(() {
      final terms = controller.data.value?.terms ?? const <TermOption>[];
      if (terms.isEmpty) return const SizedBox.shrink();
      final selected = controller.selectedTermCode;
      var label = '学期';
      for (final t in terms) {
        if (t.code == selected) {
          label = t.label;
          break;
        }
      }
      return _Card(
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined,
                size: 18, color: AppTheme.muted),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('当前学期',
                  style: TextStyle(fontSize: 14, color: AppTheme.ink)),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 176, minWidth: 128),
              child: PaperSelect(
                text: label,
                onTap: () async {
                  final next = await showPaperOptions<String>(
                    context: context,
                    title: '选择学期',
                    selected: selected,
                    options: [
                      for (final t in terms)
                        PaperOption(value: t.code, label: t.label),
                    ],
                  );
                  if (next != null) controller.changeTerm(next);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── 检查更新 ──

  Widget _buildUpdateCard() {
    return _Card(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _checking ? null : _checkUpdate,
              icon: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(_checking ? '检查中…' : '检查更新'),
            ),
          ),
          if (_updateAvailable != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _updateAvailable!.downloadUrl.isEmpty
                    ? null
                    : () => _openUrl(_updateAvailable!.downloadUrl),
                icon: const Icon(Icons.download, size: 18),
                label: Text('下载 v${_updateAvailable!.latestVersion}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── GitHub 链接 ──

  Widget _buildLinkCard() {
    return _Card(
      child: InkWell(
        onTap: () => _openUrl(AppConstants.repoUrl),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.open_in_new, size: 18, color: AppTheme.muted),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('GitHub 仓库',
                    style: TextStyle(fontSize: 14, color: AppTheme.ink)),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppTheme.faint),
            ],
          ),
        ),
      ),
    );
  }

  // ── 工具方法 ──

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final session = Get.find<SchoolSession>();
      await session.logout();
      Get.offAllNamed('/login');
    }
  }
}

// ── 通用卡片 ──

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: child,
    );
  }
}
