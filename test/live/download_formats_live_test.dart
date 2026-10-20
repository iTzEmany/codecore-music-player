// Opt-in: downloads one real song in every format with the real yt-dlp and
// ffmpeg, and reads each file back (about 1 min, ~25 MB).
//   CODECORE_LIVE=1 flutter test test/live/download_formats_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/tags/audio_metadata_tag_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  test('every format gives a readable file with the expected extension', () async {
    final dir = Directory.systemTemp.createTempSync('cc_formats');
    addTearDown(() => dir.deleteSync(recursive: true));
    final yt = YtDlpProcessService(executable: Platform.environment['YTDLP']);
    final hits = await yt.searchSongs('Lucio Corsi Sigarette', limit: 3);
    expect(hits, isNotEmpty);
    final paths = <String>[];
    for (final (format, ext) in [
      (DownloadFormat.original, '.opus'),
      (DownloadFormat.m4a, '.m4a'),
      (DownloadFormat.mp3High, '.mp3'),
      (DownloadFormat.mp3Low, '.mp3'),
    ]) {
      final watch = Stopwatch()..start();
      String? path;
      await for (final p in yt.download(hits.first, dir,
          options: DownloadOptions(format: format))) {
        path = p.path ?? path;
      }
      expect(path, endsWith(ext), reason: format.name);
      final tags = await const AudioMetadataTagReader().read(path!);
      expect(tags.durationMs, greaterThan(60000), reason: format.name);
      // ignore: avoid_print
      print('${format.name}: ${File(path).lengthSync() ~/ 1024} KB, '
          '${tags.bitrateKbps ?? '?'} kbps, ${watch.elapsedMilliseconds} ms');
      paths.add(path);
    }
    expect(paths.toSet(), hasLength(4), reason: 'a second MP3 must not overwrite the first');
  }, skip: live ? false : 'set CODECORE_LIVE=1', timeout: const Timeout(Duration(minutes: 5)));
}
