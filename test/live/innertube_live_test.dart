// Opt-in: the real direct search of YouTube and YouTube Music (a few seconds).
// A failure here means YouTube changed its answers: the app falls back on
// yt-dlp, and the fixtures in test/fixtures/innertube need refreshing.
//   CODECORE_LIVE=1 flutter test test/live/innertube_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/innertube_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  final skip = live ? false : 'set CODECORE_LIVE=1';

  test('YouTube Music songs: artist, album and length, also by ISRC', () async {
    final client = InnerTubeClient();
    final songs = await client.searchSongs('pink floyd mother');
    expect(songs, isNotEmpty);
    final mother = songs.firstWhere((s) => s.title == 'Mother');
    expect(mother.artists, contains('Pink Floyd'));
    expect(mother.album, 'The Wall');
    expect(mother.duration!.inSeconds, inInclusiveRange(330, 340));
    final byIsrc = await client.searchSongs('GBCCS1000114', limit: 3);
    expect(byIsrc.first.title, 'Singalong Junk');
    expect(byIsrc.first.artists, contains('Paul McCartney'));
  }, skip: skip);

  test('YouTube videos with channel and length', () async {
    final videos = await InnerTubeClient().searchVideos('pink floyd mother');
    expect(videos.length, greaterThanOrEqualTo(5));
    expect(videos.where((v) => v.channel.isNotEmpty && v.duration != null), isNotEmpty);
  }, skip: skip);
}
