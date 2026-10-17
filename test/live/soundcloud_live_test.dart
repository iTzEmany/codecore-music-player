// Opt-in: talks to SoundCloud through the real yt-dlp (search only, nothing is downloaded).
//   CODECORE_LIVE=1 [YTDLP=/path/to/yt-dlp] flutter test test/live/soundcloud_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  final skip = live ? null : 'set CODECORE_LIVE=1 (needs network and yt-dlp)';

  test('SoundCloud search returns full tracks only, from SoundCloud', () async {
    final yt = YtDlpProcessService(executable: Platform.environment['YTDLP']);
    final res = await yt.searchSoundCloud('daft punk one more time', limit: 5);
    expect(res, isNotEmpty);
    expect(res.length, lessThanOrEqualTo(5));
    for (final r in res) {
      expect(r.source, MediaSource.soundcloud);
      expect(r.webpageUrl, startsWith('https://soundcloud.com/'));
      expect(r.duration, isNotNull);
      expect(r.duration!.inSeconds, greaterThan(31), reason: '${r.title}: a preview slipped through');
    }
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
