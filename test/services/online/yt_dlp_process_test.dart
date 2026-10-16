import 'dart:io';

import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a flat search result', () {
    const raw = '{"entries":[{"id":"abc","title":"Song","channel":"Band",'
        '"duration":200.0,"thumbnails":[{"url":"https://t/1.jpg"},'
        '{"url":"https://t/2.jpg"}]},{"id":null}]}';
    final r = parseYtDlpJson(raw);
    expect(r.single.id, 'abc');
    expect(r.single.channel, 'Band');
    expect(r.single.duration, const Duration(seconds: 200));
    expect(r.single.thumbnailUrl, 'https://t/2.jpg');
  });

  test('parses a single video JSON', () {
    final r = parseYtDlpJson('{"id":"x","title":"T","uploader":"U"}');
    expect(r.single.channel, 'U');
  });

  test('progress lines', () {
    expect(parseProgressLine('PROG 500 1000 NA')!.fraction, 0.5);
    expect(parseProgressLine('PROG 500 NA 2000')!.total, 2000);
    expect(parseProgressLine('[download] 10%'), isNull);
  });

  test('stderr mapping', () {
    expect(ytExceptionFromStderr('ERROR: Video unavailable').kind,
        YtErrorKind.unavailable);
    expect(ytExceptionFromStderr('Temporary failure in name resolution').kind,
        YtErrorKind.network);
    expect(ytExceptionFromStderr('HTTP Error 403').kind, YtErrorKind.changed);
  });

  test('parses a YouTube Music search page with artists and album', () {
    final raw = File('test/fixtures/ytmusic_search.json').readAsStringSync();
    final r = parseYtDlpJson(raw);
    expect(r, hasLength(3));
    expect(r.first.id, 'MNvH8BzIXGY');
    expect(r.first.title, 'Felicità');
    expect(r.first.channel, 'Lucio Dalla');
    expect(r.first.artists, ['Lucio Dalla']);
    expect(r.first.album, 'Dalla/Morandi');
    expect(r.first.duration, const Duration(seconds: 345));
  });

  test('channel falls back to the first credited artist', () {
    final r = parseYtDlpJson(
        '{"id":"a","title":"T","artists":["A","B"],"duration":10}');
    expect(r.single.channel, 'A');
    expect(r.single.artists, ['A', 'B']);
  });

  test('rate limiting is told apart from unavailable videos', () {
    expect(ytExceptionFromStderr('HTTP Error 429: Too Many Requests').kind,
        YtErrorKind.rateLimited);
    expect(
        ytExceptionFromStderr(
                "ERROR: Sign in to confirm you're not a bot").kind,
        YtErrorKind.rateLimited);
    expect(ytExceptionFromStderr('Sign in to confirm your age').kind,
        YtErrorKind.unavailable);
  });

  test('YouTube Music search URL is encoded and filtered on songs', () {
    final u = youtubeMusicSearchUri('Lucio Dalla & Co: Felicità');
    expect(u.host, 'music.youtube.com');
    expect(u.queryParameters['q'], 'Lucio Dalla & Co: Felicità');
    expect(u.fragment, 'songs');
  });

  group('with a stand-in yt-dlp script', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('cc_ytdlp'));
    tearDown(() => dir.deleteSync(recursive: true));

    String fake(String version) {
      final f = File('${dir.path}/yt-dlp')
        ..writeAsStringSync('#!/bin/sh\n'
            'if [ "\$1" = "--version" ]; then echo $version; exit 0; fi\n'
            'echo "ERROR: Sign in to confirm your age" >&2\n'
            'exit 1\n');
      Process.runSync('chmod', ['+x', f.path]);
      return f.path;
    }

    test('a failing search on an old yt-dlp says it is outdated', () async {
      final svc = YtDlpProcessService(executable: fake('2024.04.09'));
      expect(await svc.toolVersion(), '2024.04.09');
      expect(
          svc.search('x'),
          throwsA(isA<YtException>()
              .having((e) => e.kind, 'kind', YtErrorKind.toolOutdated)));
    });

    test('the same failure on a recent yt-dlp stays «unavailable»', () async {
      final svc = YtDlpProcessService(executable: fake('2026.08.19'));
      expect(
          svc.searchSongs('x'),
          throwsA(isA<YtException>()
              .having((e) => e.kind, 'kind', YtErrorKind.unavailable)));
    });

    test('a search that hangs is killed after the timeout', () async {
      final pidFile = File('${dir.path}/pid');
      final f = File('${dir.path}/slow-yt-dlp')
        ..writeAsStringSync('#!/bin/sh\n'
            'if [ "\$1" = "--version" ]; then echo 2026.08.19; exit 0; fi\n'
            'echo \$\$ > ${pidFile.path}\n'
            'exec sleep 30\n');
      Process.runSync('chmod', ['+x', f.path]);
      final svc = YtDlpProcessService(
          executable: f.path, searchTimeout: const Duration(milliseconds: 400));
      await expectLater(
          svc.searchSongs('x'),
          throwsA(isA<YtException>()
              .having((e) => e.kind, 'kind', YtErrorKind.network)));
      final pid = int.parse(pidFile.readAsStringSync().trim());
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(Process.runSync('kill', ['-0', '$pid']).exitCode, isNot(0),
          reason: 'the process must be gone');
    });

    test('a missing tool has no version', () async {
      final svc = YtDlpProcessService(executable: '${dir.path}/nope');
      expect(await svc.toolVersion(), isNull);
    });
  }, skip: Platform.isWindows ? 'needs a POSIX shell' : false);
}
