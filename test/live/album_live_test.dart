// Opt-in: real YouTube Music through the real yt-dlp (about 30 s).
//   CODECORE_LIVE=1 flutter test test/live/album_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  test('album search then album page give the tracks with album and artist',
      () async {
    final yt = YtDlpProcessService(executable: Platform.environment['YTDLP']);
    final hits = await yt.searchAlbums('Lucio Corsi Volevo essere un duro');
    expect(hits, isNotEmpty);
    expect(hits.first.id, startsWith('https://music.youtube.com/browse/'));
    final tracks = await yt.albumTracks(hits.first.id);
    expect(tracks.length, greaterThanOrEqualTo(5));
    expect(tracks.map((t) => t.title), contains('Sigarette'));
    expect(tracks.first.album, 'Volevo essere un duro');
    expect(tracks.first.artists, contains('Lucio Corsi'));
    final sigarette = tracks.firstWhere((t) => t.title == 'Sigarette');
    expect(sigarette.duration!.inSeconds, inInclusiveRange(175, 185));
  }, skip: live ? false : 'set CODECORE_LIVE=1', timeout: const Timeout(Duration(minutes: 3)));
}
