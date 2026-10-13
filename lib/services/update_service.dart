import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_toast.dart';

class UpdateInfo {
  final String version;
  final String title;
  final String notes;
  final String releasePageUrl;
  final String downloadUrl;
  final String? publishedAt;

  UpdateInfo({
    required this.version,
    required this.title,
    required this.notes,
    required this.releasePageUrl,
    required this.downloadUrl,
    this.publishedAt,
  });
}

class UpdateService {
  static const String currentVersion = '1.0.5';
  static const String repoOwner = 'Lzh3070';
  static const String repoName = 'fit-cycle';
  static bool enableNetworkCheck = true;

  static Future<void> openExternalUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Launch URL error: $e');
      if (context.mounted) {
        AppToast.error(context, '无法打开浏览器链接，请检查浏览器');
      }
    }
  }

  static Future<UpdateInfo?> checkUpdate() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    client.userAgent = 'FitCycle-App';

    try {
      final uri = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;

        final rawTag = data['tag_name'] as String? ?? '';
        final remoteVer = rawTag.replaceAll(RegExp(r'^[vV]'), '').trim();

        if (_isNewer(remoteVer, currentVersion)) {
          final title = data['name'] as String? ?? 'v$remoteVer';
          final notes = data['body'] as String? ?? '无更新日志说明';
          final htmlUrl = data['html_url'] as String? ?? 'https://github.com/$repoOwner/$repoName/releases';
          final publishedAt = data['published_at'] as String?;

          String downloadUrl = htmlUrl;
          final assets = data['assets'] as List<dynamic>?;
          if (assets != null && assets.isNotEmpty) {
            for (final asset in assets) {
              final name = asset['name'] as String? ?? '';
              if (name.toLowerCase().endsWith('.apk')) {
                downloadUrl = asset['browser_download_url'] as String? ?? htmlUrl;
                break;
              }
            }
          }

          return UpdateInfo(
            version: remoteVer,
            title: title,
            notes: notes,
            releasePageUrl: htmlUrl,
            downloadUrl: downloadUrl,
            publishedAt: publishedAt,
          );
        }
      }
      return null;
    } finally {
      client.close();
    }
  }

  static bool _isNewer(String remote, String local) {
    try {
      final rParts = remote.split('.').map(int.parse).toList();
      final lParts = local.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
      return false;
    } catch (_) {
      return remote != local;
    }
  }

  static Future<void> performCheck(BuildContext context, {bool isManual = true}) async {
    if (!enableNetworkCheck) return;
    if (isManual) {
      AppToast.info(context, '正在检查最新版本...');
    }

    try {
      final updateInfo = await checkUpdate();
      if (!context.mounted) return;

      if (updateInfo != null) {
        showUpdateDialog(context, updateInfo);
      } else {
        if (isManual) {
          AppToast.success(context, '当前已是最新版本 (v$currentVersion)');
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      if (isManual) {
        AppToast.error(context, '检查更新失败：网络连接异常，建议稍后重试');
      }
    }
  }

  static void showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF064E3B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF34D399), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '发现新版本 v${updateInfo.version}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      updateInfo.title,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxHeight: 280),
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      updateInfo.notes,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('稍后再说', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await openExternalUrl(context, updateInfo.downloadUrl);
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('立即更新', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
