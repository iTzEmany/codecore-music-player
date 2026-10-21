import 'package:codecore/services/online/album_download_plan.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:flutter_test/flutter_test.dart';

YtResult _song(String id, int seconds) =>
    YtResult(id: id, title: 'Song $id', channel: 'c', duration: Duration(seconds: seconds));

YtmAlbum _album(List<YtmAlbumTrack> tracks, {String title = 'The Wall', String? artist = 'Pink Floyd'}) =>
    YtmAlbum(
      browseId: 'MPREb_x',
      title: title,
      artist: artist == null ? null : YtmArtistRef(id: 'UC1', name: artist),
      tracks: tracks,
    );

void main() {
  test('names the import and the folder; forbidden characters leave the folder name', () {
    final plan = albumDownloadPlan(
        _album([YtmAlbumTrack(1, _song('a', 60))], title: 'AC/DC: Live?'), (_) => false);
    expect(plan.importName, 'AC/DC: Live? — Pink Floyd');
    expect(plan.folder, isNot(contains('/')));
    expect(plan.folder, isNot(contains(':')));
    expect(plan.folder, startsWith('Pink Floyd - '));
  });

  test('without an artist both names are the album title', () {
    final plan = albumDownloadPlan(_album(const [], artist: null), (_) => false);
    expect(plan.importName, 'The Wall');
    expect(plan.folder, 'The Wall');
  });

  test('the songs keep the album order, by number when the page gave them', () {
    final plan = albumDownloadPlan(
        _album([YtmAlbumTrack(2, _song('b', 60)), YtmAlbumTrack(1, _song('a', 60))]), (_) => false);
    expect(plan.tracks.map((t) => t.id), ['a', 'b']);
    final unnumbered = albumDownloadPlan(
        _album([YtmAlbumTrack(null, _song('b', 60)), YtmAlbumTrack(null, _song('a', 60))]), (_) => false);
    expect(unnumbered.tracks.map((t) => t.id), ['b', 'a'], reason: 'as the page listed them');
  });

  test('counts what the library has and weighs only the rest (about 1 MB a minute)', () {
    final plan = albumDownloadPlan(
      _album([
        YtmAlbumTrack(1, _song('a', 180)),
        YtmAlbumTrack(2, _song('b', 240)),
        YtmAlbumTrack(3, _song('c', 120)),
      ]),
      (r) => r.id == 'b',
    );
    expect(plan.owned, 1);
    expect(plan.duration, const Duration(seconds: 540));
    expect(plan.estimatedBytes, 5 * 1024 * 1024);
  });
}
