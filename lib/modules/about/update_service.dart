import 'dart:convert';
import 'dart:io';

import '../../core/constants.dart';

class UpdateResult {
  const UpdateResult({
    required this.hasUpdate,
    required this.latestVersion,
    this.downloadUrl = '',
    this.error = '',
  });

  final bool hasUpdate;
  final String latestVersion;
  final String downloadUrl;
  final String error;

  bool get isError => error.isNotEmpty;
}

class UpdateService {
  Future<UpdateResult> check() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      try {
        final request = await client.getUrl(Uri.parse(AppConstants.releasesApi));
        request.headers.set('Accept', 'application/vnd.github+json');
        final response = await request.close().timeout(const Duration(seconds: 15));
        final bytes = await response.fold<List<int>>([], (p, c) => p..addAll(c));
        final body = utf8.decode(bytes, allowMalformed: true);

        if (response.statusCode != 200) {
          return UpdateResult(
            hasUpdate: false,
            latestVersion: '',
            error: '服务器返回 ${response.statusCode}',
          );
        }

        final json = jsonDecode(body);
        if (json is! Map) {
          return UpdateResult(
            hasUpdate: false,
            latestVersion: '',
            error: '响应格式异常',
          );
        }

        final tag = (json['tag_name'] ?? '').toString().replaceFirst('v', '');
        final assets = (json['assets'] as List?) ?? const [];
        var downloadUrl = '';
        for (final asset in assets) {
          if (asset is Map) {
            final name = (asset['name'] ?? '').toString().toLowerCase();
            if (name.endsWith('.apk')) {
              downloadUrl = (asset['browser_download_url'] ?? '').toString();
              break;
            }
          }
        }

        final current = _normalizeVersion(AppConstants.appVersion);
        final latest = _normalizeVersion(tag);
        final hasUpdate = _isNewer(latest, current);

        return UpdateResult(
          hasUpdate: hasUpdate,
          latestVersion: tag,
          downloadUrl: downloadUrl,
        );
      } finally {
        client.close(force: true);
      }
    } on SocketException {
      return const UpdateResult(
        hasUpdate: false,
        latestVersion: '',
        error: '网络连接失败，请检查网络后重试',
      );
    } on HttpException {
      return const UpdateResult(
        hasUpdate: false,
        latestVersion: '',
        error: '网络请求异常',
      );
    } catch (e) {
      return UpdateResult(
        hasUpdate: false,
        latestVersion: '',
        error: '$e',
      );
    }
  }

  List<int> _normalizeVersion(String version) {
    final cleaned = version.replaceFirst(RegExp(r'\+.*$'), '');
    return cleaned.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  bool _isNewer(List<int> latest, List<int> current) {
    final len = latest.length > current.length ? latest.length : current.length;
    for (var i = 0; i < len; i++) {
      final l = i < latest.length ? latest[i] : 0;
      final c = i < current.length ? current[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
