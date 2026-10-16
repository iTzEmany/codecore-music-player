import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:typed_data';

import 'package:codecore/services/online/yt_dlp_updater.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves GitHub-like responses from memory.
class FakeGithub implements HttpClientAdapter {
  FakeGithub(this.binary, {String? sumsFor, this.assetNames = const [
    'yt-dlp_linux', 'yt-dlp.exe', 'yt-dlp_linux_aarch64', 'SHA2-256SUMS'
  ]}) : hash = sha256.convert(sumsFor == null ? binary : utf8.encode(sumsFor)).toString();

  final List<int> binary;
  final String hash;
  final List<String> assetNames;
  final requested = <String>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    final url = o.uri.toString();
    requested.add(url);
    if (url.endsWith('/releases/latest')) {
      return ResponseBody.fromString(
          jsonEncode({
            'tag_name': '2026.08.19',
            'assets': [
              for (final n in assetNames)
                {'name': n, 'browser_download_url': 'https://dl/$n'},
            ],
          }),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']});
    }
    if (url.endsWith('SHA2-256SUMS')) {
      return ResponseBody.fromString(
          '$hash  yt-dlp_linux\n$hash  yt-dlp.exe\n', 200);
    }
    return ResponseBody.fromBytes(binary, 200, headers: {
      Headers.contentLengthHeader: ['${binary.length}'],
    });
  }
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('cc_upd'));
  tearDown(() => dir.deleteSync(recursive: true));

  YtDlpUpdater updater(FakeGithub g, {Abi? abi, bool windows = false}) =>
      YtDlpUpdater(
          dio: Dio()..httpClientAdapter = g,
          binDir: '${dir.path}/bin',
          abi: abi ?? Abi.linuxX64,
          windows: windows);

  test('asset per platform and architecture', () {
    expect(ytDlpAssetFor(Abi.linuxX64), 'yt-dlp_linux');
    expect(ytDlpAssetFor(Abi.linuxArm64), 'yt-dlp_linux_aarch64');
    expect(ytDlpAssetFor(Abi.windowsX64), 'yt-dlp.exe');
    expect(ytDlpAssetFor(Abi.windowsArm64), 'yt-dlp_arm64.exe');
    expect(ytDlpAssetFor(Abi.macosArm64), isNull);
  });

  test('SHA2-256SUMS parsing', () {
    final h = 'a' * 64;
    expect(parseSha256Sums('$h  yt-dlp\n${'B' * 64}  *yt-dlp.exe\nbad line\n'),
        {'yt-dlp': h, 'yt-dlp.exe': 'b' * 64});
  });

  test('installs a verified binary and keeps the previous one as .old',
      () async {
    final u = updater(FakeGithub(utf8.encode('#!/bin/sh\necho new\n')));
    Directory('${dir.path}/bin').createSync();
    File(u.binaryPath).writeAsStringSync('old');
    final progress = <double>[];
    expect(await u.update(onProgress: progress.add), '2026.08.19');
    expect(File(u.binaryPath).readAsStringSync(), contains('echo new'));
    expect(File('${u.binaryPath}.old').readAsStringSync(), 'old');
    expect(File('${u.binaryPath}.download').existsSync(), isFalse);
    expect(progress.last, 1.0);
    if (!Platform.isWindows) {
      expect(File(u.binaryPath).statSync().mode & 0x40, isNonZero,
          reason: 'executable bit');
    }
  }, skip: Platform.isWindows);

  test('a wrong hash leaves the old binary alone and no leftovers', () async {
    final u = updater(FakeGithub(utf8.encode('evil'), sumsFor: 'something else'));
    Directory('${dir.path}/bin').createSync();
    File(u.binaryPath).writeAsStringSync('old');
    await expectLater(
        u.update(),
        throwsA(isA<YtDlpUpdateException>().having(
            (e) => e.kind, 'kind', YtDlpUpdateError.hashMismatch)));
    expect(File(u.binaryPath).readAsStringSync(), 'old');
    expect(File('${u.binaryPath}.old').existsSync(), isFalse);
    expect(File('${u.binaryPath}.download').existsSync(), isFalse);
  });

  test('the first install works with no previous binary', () async {
    final u = updater(FakeGithub(utf8.encode('x')));
    await u.update();
    expect(File(u.binaryPath).readAsStringSync(), 'x');
    expect(File('${u.binaryPath}.old').existsSync(), isFalse);
  });

  test('picks the Windows asset and file name', () async {
    final g = FakeGithub(utf8.encode('exe'));
    final u = updater(g, abi: Abi.windowsX64, windows: true);
    await u.update();
    expect(u.binaryPath, endsWith('yt-dlp.exe'));
    expect(g.requested, contains('https://dl/yt-dlp.exe'));
  });

  test('missing asset and unsupported platform are explained', () async {
    final noSums = FakeGithub(utf8.encode('x'), assetNames: ['yt-dlp_linux']);
    await expectLater(
        updater(noSums).update(),
        throwsA(isA<YtDlpUpdateException>().having(
            (e) => e.kind, 'kind', YtDlpUpdateError.assetMissing)));
    await expectLater(
        updater(FakeGithub(utf8.encode('x')), abi: Abi.macosArm64).update(),
        throwsA(isA<YtDlpUpdateException>().having(
            (e) => e.kind, 'kind', YtDlpUpdateError.unsupportedPlatform)));
  });
}
