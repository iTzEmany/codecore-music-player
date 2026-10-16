// Opt-in: downloads the real yt-dlp binary (~40 MB) into a temp folder.
//   CODECORE_LIVE=1 flutter test test/live/yt_dlp_update_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/http_client.dart';
import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:codecore/services/online/yt_dlp_updater.dart';
import 'package:codecore/services/online/yt_dlp_version.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  test('installs the latest official yt-dlp and runs it', () async {
    final dir = Directory.systemTemp.createTempSync('cc_ytdlp_live');
    addTearDown(() => dir.deleteSync(recursive: true));
    final updater = YtDlpUpdater(
      dio: Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'User-Agent': DioWebClient.userAgent},
      )),
      binDir: '${dir.path}/bin',
    );
    final tag = await updater.update();
    final svc = YtDlpProcessService(executable: updater.binaryPath);
    final version = await svc.toolVersion();
    expect(parseYtDlpVersion(tag), isNotNull);
    expect(version, isNotNull);
    expect(isYtDlpOutdated(version), isFalse);
  }, skip: live ? false : 'set CODECORE_LIVE=1', timeout: const Timeout(Duration(minutes: 3)));
}
