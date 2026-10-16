import 'package:codecore/services/online/yt_dlp_args.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> args({
  DownloadOptions options = const DownloadOptions(),
  bool hasFfmpeg = true,
}) =>
    buildDownloadArgs(
        id: 'abc',
        stem: '/d/Song',
        hasFfmpeg: hasFfmpeg,
        options: options,
        jsArgs: ['--js-runtimes', 'node']);

void main() {
  test('default: MP3 256k, no rate limit', () {
    final a = args();
    expect(
        a,
        containsAllInOrder([
          '-f', 'bestaudio/best', '-x', '--audio-format', 'mp3',
          '--audio-quality', '256K',
        ]));
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
    expect(args(), isNot(contains('--limit-rate')));
  });

  test('original format: prefer m4a, extract without --audio-format', () {
    final a = args(options: const DownloadOptions(format: DownloadFormat.original));
    expect(a, containsAllInOrder(['-f', 'bestaudio[ext=m4a]/bestaudio/best', '-x']));
    expect(a, isNot(contains('--audio-format')));
    expect(a, isNot(contains('--audio-quality')));
  });

  test('without ffmpeg the audio is kept as downloaded, whatever the format', () {
    for (final f in DownloadFormat.values) {
      final a = args(hasFfmpeg: false, options: DownloadOptions(format: f));
      expect(a, containsAllInOrder(['-f', 'bestaudio[ext=m4a]/bestaudio/best']));
      expect(a, isNot(contains('-x')));
    }
  });

  test('reserved extension follows what will be produced', () {
    expect(reservedExtension(hasFfmpeg: true, options: const DownloadOptions()), 'mp3');
    expect(
        reservedExtension(
            hasFfmpeg: true,
            options: const DownloadOptions(format: DownloadFormat.original)),
        'm4a');
    expect(reservedExtension(hasFfmpeg: false, options: const DownloadOptions()), 'm4a');
  });

  test('a name taken by any container is not reused', () {
    final taken = {'/d/Song.opus'};
    expect(anyDownloadExtensionExists('/d/Song.m4a', taken.contains), isTrue);
    expect(anyDownloadExtensionExists('/d/Other.m4a', taken.contains), isFalse);
  });
}
