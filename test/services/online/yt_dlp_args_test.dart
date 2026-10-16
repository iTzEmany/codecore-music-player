import 'package:codecore/services/online/yt_dlp_args.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> args({DownloadOptions options = const DownloadOptions(), bool convert = true}) =>
    buildDownloadArgs(
        id: 'abc', stem: '/d/Song', convert: convert, options: options, jsArgs: ['--js-runtimes', 'node']);

void main() {
  test('default: MP3 256k, no rate limit', () {
    final a = args();
    expect(a, containsAllInOrder(['-f', 'bestaudio/best', '-x', '--audio-format', 'mp3', '--audio-quality', '256K']));
    expect(a, isNot(contains('--limit-rate')));
    expect(a, containsAllInOrder(['--js-runtimes', 'node']));
    expect(a.last, 'https://www.youtube.com/watch?v=abc');
    expect(a, containsAllInOrder(['-o', '/d/Song.%(ext)s']));
  });

  test('rate limit becomes --limit-rate <n>K; 0 and null mean unlimited', () {
    expect(args(options: const DownloadOptions(rateLimitKBps: 500)),
        containsAllInOrder(['--limit-rate', '500K']));
    expect(args(options: const DownloadOptions(rateLimitKBps: 0)),
        isNot(contains('--limit-rate')));
    expect(args(options: const DownloadOptions()), isNot(contains('--limit-rate')));
  });

  test('without ffmpeg the m4a is kept as downloaded', () {
    final a = args(convert: false);
    expect(a, containsAllInOrder(['-f', 'bestaudio[ext=m4a]/bestaudio/best']));
    expect(a, isNot(contains('-x')));
  });
}
