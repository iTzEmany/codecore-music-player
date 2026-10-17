// Opt-in: lists a real public YouTube playlist and channel with the real yt-dlp (nothing is downloaded).
//   CODECORE_LIVE=1 [YTDLP=/path/to/yt-dlp] flutter test test/live/yt_playlist_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:codecore/services/online/youtube_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  final skip = live ? null : 'set CODECORE_LIVE=1 (needs network and yt-dlp)';
  final yt = YtDlpProcessService(executable: Platform.environment['YTDLP']);

  test('a public playlist lists its videos in order', () async {
    final url = listingUrl('https://www.youtube.com/playlist?list=PLzH6n4zXuckpHPMGkHuMoBDQuav3lq5U0')!;
    final l = await yt.listPlaylist(url);
    expect(l.title, isNotEmpty);
    expect(l.entries, isNotEmpty);
    expect(l.entries.map((e) => e.id).toSet(), hasLength(l.entries.length));
    expect(l.entries.every((e) => e.channel.isNotEmpty), isTrue);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('a channel lists its latest videos, up to the limit', () async {
    final url = listingUrl('https://www.youtube.com/@Computerphile')!;
    final l = await yt.listPlaylist(url, limit: 40);
    expect(l.entries, hasLength(40));
    expect(l.truncated, isTrue);
    expect(l.title, isNot(endsWith('Videos')), reason: 'the tab name is dropped');
    expect(l.entries.first.channel, 'Computerphile');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
