// Opt-in: downloads one real song twice (MP3 and original) with the real yt-dlp.
//   CODECORE_LIVE=1 flutter test test/live/original_format_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/tags/audio_metadata_tag_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  test('the original format keeps the served audio and stays readable', () async {
    final dir = Directory.systemTemp.createTempSync('cc_orig');
    addTearDown(() => dir.deleteSync(recursive: true));
    final yt = YtDlpProcessService(executable: Platform.environment['YTDLP']);
    final hits = await yt.searchSongs('Lucio Corsi Sigarette', limit: 3);
    expect(hits, isNotEmpty);
    String? path;
    await for (final p in yt.download(hits.first, dir,
        options: const DownloadOptions(format: DownloadFormat.original))) {
      path = p.path ?? path;
    }
    expect(path, isNotNull);
    expect(path, anyOf(endsWith('.m4a'), endsWith('.opus'), endsWith('.webm')));
    final tags = await const AudioMetadataTagReader().read(path!);
    expect(tags.durationMs, greaterThan(60000));
    // A second one must not overwrite the first.
    String? again;
    await for (final p in yt.download(hits.first, dir,
        options: const DownloadOptions(format: DownloadFormat.original))) {
      again = p.path ?? again;
    }
    expect(again, isNot(path));
    expect(dir.listSync().length, 2);
  }, skip: live ? false : 'set CODECORE_LIVE=1', timeout: const Timeout(Duration(minutes: 3)));
}
