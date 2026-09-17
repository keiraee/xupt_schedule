import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/constants.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error)),
      );
    } else if (result.hasUpdate) {
      setState(() => _updateAvailable = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发现新版本 v${result.latestVersion}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前已是最新版本')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F5F1),
        title: const Text('关于'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildUpdateCard(),
            const SizedBox(height: 16),
            _buildLinkCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          AppConstants.badgeAsset,
          width: 72,
          height: 72,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 14),
        Text(
          AppConstants.appName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'v${AppConstants.appVersion}',
          style: const TextStyle(fontSize: 13, color: AppTheme.muted),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return _Card(
      children: [
        _infoRow(Icons.school_outlined, '西安邮电大学课表客户端'),
        const SizedBox(height: 10),
        _infoRow(Icons.link_off, '直连学校统一认证，无需后端服务'),
        const SizedBox(height: 10),
        _infoRow(Icons.code, 'Flutter / Dart · GetX'),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppTheme.ink),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateCard() {
    return _Card(
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
    );
  }

  Widget _buildLinkCard() {
    return _Card(
      children: [
        _linkRow(Icons.open_in_new, 'GitHub 仓库', AppConstants.repoUrl),
      ],
    );
  }

  Widget _linkRow(IconData icon, String label, String url) {
    return InkWell(
      onTap: () => _openUrl(url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: AppTheme.ink),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.faint),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
