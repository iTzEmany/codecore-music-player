import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';

enum YtDlpUpdateError {
  unsupportedPlatform,
  network,
  assetMissing,
  hashMismatch,
  installFailed,
}

class YtDlpUpdateException implements Exception {
  const YtDlpUpdateException(this.kind, [this.detail]);

  final YtDlpUpdateError kind;
  final String? detail;

  @override
  String toString() => 'YtDlpUpdateException($kind, $detail)';
}

const _releaseUrl =
    'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest';
const _sumsName = 'SHA2-256SUMS';

/// Name of the official release asset for [abi]; null where there is none.
String? ytDlpAssetFor(Abi abi) {
  if (abi == Abi.linuxX64) return 'yt-dlp_linux';
  if (abi == Abi.linuxArm64) return 'yt-dlp_linux_aarch64';
  if (abi == Abi.windowsX64) return 'yt-dlp.exe';
  if (abi == Abi.windowsArm64) return 'yt-dlp_arm64.exe';
  return null;
}

/// `<hash>  <name>` lines of `SHA2-256SUMS`.
Map<String, String> parseSha256Sums(String text) {
  final out = <String, String>{};
  for (final line in text.split('\n')) {
    final m = RegExp(r'^([0-9a-fA-F]{64})\s+\*?(\S+)\s*$').firstMatch(line);
    if (m != null) out[m[2]!] = m[1]!.toLowerCase();
  }
  return out;
}

/// Path of the yt-dlp binary the app manages inside [binDir].
String managedYtDlpPath(String binDir, {bool? windows}) =>
    p.join(binDir, (windows ?? Platform.isWindows) ? 'yt-dlp.exe' : 'yt-dlp');

/// Downloads the official yt-dlp binary, checks it against the release's
/// `SHA2-256SUMS` and swaps it in atomically, keeping the old one as `.old`.
class YtDlpUpdater {
  YtDlpUpdater({
    required this.dio,
    required this.binDir,
    Abi? abi,
    bool? windows,
  })  : _abi = abi ?? Abi.current(),
        _windows = windows ?? Platform.isWindows;

  final Dio dio;
  final String binDir;
  final Abi _abi;
  final bool _windows;

  String get binaryPath => managedYtDlpPath(binDir, windows: _windows);

  /// Release tag (`2026.08.19`) and the download URL of each asset.
  Future<({String tag, Map<String, String> assets})> latest() async {
    try {
      final res = await dio.get<Object?>(_releaseUrl,
          options: Options(responseType: ResponseType.json));
      final data = res.data;
      if (res.statusCode != 200 || data is! Map) {
        throw YtDlpUpdateException(
            YtDlpUpdateError.network, 'HTTP ${res.statusCode}');
      }
      return (
        tag: '${data['tag_name']}',
        assets: {
          for (final a in (data['assets'] as List? ?? const []))
            if (a is Map) '${a['name']}': '${a['browser_download_url']}',
        },
      );
    } on DioException catch (e) {
      throw YtDlpUpdateException(YtDlpUpdateError.network, '${e.message}');
    }
  }

  /// Installs the latest release and returns its tag. The previous binary
  /// stays untouched unless the new one is complete and verified.
  Future<String> update({void Function(double fraction)? onProgress}) async {
    final name = ytDlpAssetFor(_abi);
    if (name == null) {
      throw YtDlpUpdateException(
          YtDlpUpdateError.unsupportedPlatform, '$_abi');
    }
    final release = await latest();
    final url = release.assets[name];
    final sumsUrl = release.assets[_sumsName];
    if (url == null || sumsUrl == null) {
      throw YtDlpUpdateException(YtDlpUpdateError.assetMissing, name);
    }
    final expected = await _expectedHash(sumsUrl, name);

    await Directory(binDir).create(recursive: true);
    final part = File('$binaryPath.download');
    try {
      await dio.download(url, part.path,
          onReceiveProgress: (got, total) {
        if (total > 0) onProgress?.call(got / total);
      });
      final actual = (await sha256.bind(part.openRead()).first).toString();
      if (actual != expected) {
        throw YtDlpUpdateException(
            YtDlpUpdateError.hashMismatch, 'expected $expected got $actual');
      }
      await _install(part);
    } on DioException catch (e) {
      throw YtDlpUpdateException(YtDlpUpdateError.network, '${e.message}');
    } finally {
      // Our own temporary file: never the user's.
      if (await part.exists()) await part.delete();
    }
    return release.tag;
  }

  Future<String> _expectedHash(String sumsUrl, String name) async {
    try {
      final res = await dio.get<String>(sumsUrl,
          options: Options(responseType: ResponseType.plain));
      final hash = parseSha256Sums(res.data ?? '')[name];
      if (res.statusCode != 200 || hash == null) {
        throw YtDlpUpdateException(YtDlpUpdateError.assetMissing, _sumsName);
      }
      return hash;
    } on DioException catch (e) {
      throw YtDlpUpdateException(YtDlpUpdateError.network, '${e.message}');
    }
  }

  Future<void> _install(File verified) async {
    if (!_windows) {
      final r = await Process.run('chmod', ['+x', verified.path]);
      if (r.exitCode != 0) {
        throw YtDlpUpdateException(YtDlpUpdateError.installFailed, r.stderr.toString());
      }
    }
    final current = File(binaryPath);
    final old = File('$binaryPath.old');
    var movedOld = false;
    try {
      if (await current.exists()) {
        if (await old.exists()) await old.delete();
        await current.rename(old.path);
        movedOld = true;
      }
      await verified.rename(binaryPath);
    } on FileSystemException catch (e, st) {
      AppLog.e('yt-dlp install failed', e, st);
      if (movedOld && !await current.exists()) await old.rename(binaryPath);
      throw YtDlpUpdateException(YtDlpUpdateError.installFailed, e.message);
    }
  }
}
