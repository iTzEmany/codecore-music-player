import '../../core/text_utils.dart';
import 'innertube_client.dart' show InnerTubeChanged;
import 'innertube_json.dart';
import 'ytm_artist.dart';
import 'ytm_artist_parser.dart';
import 'youtube_service.dart';

final _year = RegExp(r'^\d{4}$');

/// An album page (`browse` of an `MPREb_…` id). The record's artist (from the
/// strapline) stands in for the artist of every row that names none.
YtmAlbum parseAlbumPage(Map data, String browseId) {
  final contents = data['contents'];
  if (contents is! Map || contents['twoColumnBrowseResultsRenderer'] is! Map) {
    throw const InnerTubeChanged('no twoColumnBrowseResultsRenderer');
  }
  final headers = collectRenderers(contents, 'musicResponsiveHeaderRenderer');
  if (headers.isEmpty) throw const InnerTubeChanged('no musicResponsiveHeaderRenderer');
  final header = headers.first;
  final title = htmlUnescape(runsText(header['title']));
  if (title.isEmpty) throw const InnerTubeChanged('album without a title');

  YtmArtistRef? artist;
  final strap = header['straplineTextOne'];
  for (final r in strap is Map && strap['runs'] is List ? strap['runs'] as List : const []) {
    final id = browseIdOf(r);
    if (id != null && pageTypeOf(r) == 'MUSIC_PAGE_TYPE_ARTIST') {
      artist = YtmArtistRef(id: id, name: htmlUnescape((r as Map)['text'] as String));
      break;
    }
  }

  final subtitle = [for (final g in bulletGroups(header['subtitle'])) groupText(g)];
  final year = subtitle.where(_year.hasMatch).firstOrNull;
  final kind = subtitle.isEmpty || _year.hasMatch(subtitle.first) ? null : subtitle.first;
  final cover = pickThumbnail(header['thumbnail'], minWidth: 544);

  final tracks = <YtmAlbumTrack>[];
  for (final row in collectRenderers(contents['twoColumnBrowseResultsRenderer'],
      'musicResponsiveListItemRenderer')) {
    final r = parseSongRow(row,
        defaultArtist: artist,
        defaultAlbum: title,
        defaultAlbumId: browseId,
        defaultThumbnail: cover);
    if (r == null) continue;
    tracks.add(YtmAlbumTrack(int.tryParse(runsText(row['index'])), r));
  }
  return YtmAlbum(
    browseId: browseId,
    title: title,
    artist: artist,
    year: year,
    kindLabel: kind,
    coverUrl: cover,
    tracks: tracks,
  );
}

/// The songs of a `VL…` list page («Top songs»): at most the first page of
/// 100, with their length; the continuation is ignored.
List<YtResult> parseSongList(Map data) {
  final contents = data['contents'];
  final shelves = contents is Map
      ? [
          ...collectRenderers(contents, 'musicPlaylistShelfRenderer'),
          ...collectRenderers(contents, 'musicShelfRenderer'),
        ]
      : const <Map>[];
  if (shelves.isEmpty) throw const InnerTubeChanged('no song list');
  return [
    for (final row
        in collectRenderers(shelves.first['contents'], 'musicResponsiveListItemRenderer'))
      ?parseSongRow(row),
  ];
}

/// The releases of a discography page (`MPAD…`), in YouTube's order.
List<YtmRelease> parseDiscography(Map data) {
  final contents = data['contents'];
  if (contents is! Map ||
      (collectRenderers(contents, 'gridRenderer').isEmpty &&
          collectRenderers(contents, 'musicCarouselShelfRenderer').isEmpty)) {
    throw const InnerTubeChanged('no discography grid');
  }
  return [
    for (final t in collectRenderers(contents, 'musicTwoRowItemRenderer'))
      ?parseReleaseTile(t),
  ];
}
