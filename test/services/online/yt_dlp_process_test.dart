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

  test('album search results are the browse links, nothing else', () {
    const raw = '{"entries":['
        '{"id":"MPREb_1","url":"https://music.youtube.com/browse/MPREb_1","title":null},'
        '{"id":"x","url":"https://example.com/other"},'
        '{"id":"MPREb_2","url":"https://music.youtube.com/browse/MPREb_2"}]}';
    final links = parseYtAlbumLinks(raw);
    expect(links.map((l) => l.id), [
      'https://music.youtube.com/browse/MPREb_1',
      'https://music.youtube.com/browse/MPREb_2',
    ]);
    expect(parseYtAlbumLinks('{}'), isEmpty);
  });

  test('an album page parses into its tracks with album and artists', () {
    const raw = '{"title":"Album - Volevo essere un duro","entries":['
        '{"id":"a","title":"Sigarette","artists":["Lucio Corsi"],'
        '"album":"Volevo essere un duro","duration":180},'
        '{"id":"b","title":"Francis Delacroix","artists":["Lucio Corsi"],'
        '"album":"Volevo essere un duro","duration":193}]}';
    final t = parseYtDlpJson(raw);
    expect(t.map((x) => x.title), ['Sigarette', 'Francis Delacroix']);
    expect(t.first.album, 'Volevo essere un duro');
    expect(t.first.artists, ['Lucio Corsi']);
    expect(t.first.duration, const Duration(seconds: 180));
  });

  test('the YouTube Music albums URL is filtered on albums', () {
    final u = youtubeMusicAlbumsUri('Lucio Corsi Volevo essere un duro');
    expect(u.host, 'music.youtube.com');
    expect(u.fragment, 'albums');
    expect(u.queryParameters['q'], 'Lucio Corsi Volevo essere un duro');
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

    test('the SoundCloud search asks for a flat scsearch, drops the previews and trims to the limit', () async {
      final argsFile = File('${dir.path}/args');
      final json = File('test/fixtures/scsearch_flat.json').absolute.path;
      final f = File('${dir.path}/sc-yt-dlp')
        ..writeAsStringSync('#!/bin/sh\n'
            'if [ "\$1" = "--version" ]; then echo 2026.08.19; exit 0; fi\n'
            'echo "\$@" > ${argsFile.path}\n'
            'cat $json\n');
      Process.runSync('chmod', ['+x', f.path]);
      final svc = YtDlpProcessService(executable: f.path);

      final res = await svc.searchSoundCloud('daft punk one more time', limit: 3);

      expect(argsFile.readAsStringSync().trim(),
          '-J --no-warnings --flat-playlist scsearch8:daft punk one more time');
      expect(res, hasLength(3));
      expect(res.every((r) => r.source == MediaSource.soundcloud && r.duration! > const Duration(seconds: 31)), isTrue);
    });

    test('a playlist is listed flat, up to the limit, and parsed', () async {
      final argsFile = File('${dir.path}/pl-args');
      final json = File('test/fixtures/yt_playlist_flat.json').absolute.path;
      final f = File('${dir.path}/pl-yt-dlp')
        ..writeAsStringSync('#!/bin/sh\n'
            'if [ "\$1" = "--version" ]; then echo 2026.08.19; exit 0; fi\n'
            'echo "\$@" > ${argsFile.path}\n'
            'cat $json\n');
      Process.runSync('chmod', ['+x', f.path]);
      final svc = YtDlpProcessService(executable: f.path);

      final l = await svc.listPlaylist('https://www.youtube.com/playlist?list=PLx', limit: 300);

      expect(argsFile.readAsStringSync().trim(),
          '-J --no-warnings --flat-playlist --playlist-items 1-300 https://www.youtube.com/playlist?list=PLx');
      expect(l.entries, hasLength(5));
      expect(l.unavailable, 1);
    });

    test('a playlist that cannot be read says why', () async {
      final svc = YtDlpProcessService(executable: fake('2026.08.19'));
      expect(
          svc.listPlaylist('https://www.youtube.com/playlist?list=PLx'),
          throwsA(isA<YtException>().having((e) => e.kind, 'kind', YtErrorKind.unavailable)));
    });

    test('a blank SoundCloud query does not start a process', () async {
      final svc = YtDlpProcessService(executable: '/nonexistent/yt-dlp');
      expect(await svc.searchSoundCloud('   '), isEmpty);
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
