import '../../core/text_utils.dart';
import 'innertube_client.dart' show ArtistNotFound, InnerTubeChanged;
import 'innertube_json.dart';
import 'ytm_artist.dart';
import 'youtube_service.dart';

const _artistType = 'MUSIC_PAGE_TYPE_ARTIST';
const _albumType = 'MUSIC_PAGE_TYPE_ALBUM';

/// The link of an `…Endpoint` map (`onTap`, `navigationEndpoint`) read like a run's.
Map _asRun(Object? endpoint) => {'navigationEndpoint': endpoint};

String? _audience(Object? subtitle) {
  final groups = bulletGroups(subtitle);
  // The first group is the kind («Artist»), the last one the audience.
  return groups.length < 2 ? null : groupText(groups.last);
}

/// The “top result” card of an unfiltered YouTube Music search, when it is an
/// artist; null for a song, an album or no card.
YtmArtistRef? parseTopArtistCard(Map data) {
  final cards = collectRenderers(data['contents'], 'musicCardShelfRenderer');
  if (cards.isEmpty) return null;
  final card = cards.first;
  final onTap = _asRun(card['onTap']);
  if (pageTypeOf(onTap) != _artistType) return null;
  final id = browseIdOf(onTap);
  final name = runsText(card['title']);
  if (id == null || name.isEmpty) return null;
  return YtmArtistRef(
    id: id,
    name: htmlUnescape(name),
    thumbnailUrl: pickThumbnail(card['thumbnail']),
    audience: _audience(card['subtitle']),
  );
}

/// The artists of a YouTube Music search filtered on artists, best first.
List<YtmArtistRef> parseArtistSearch(Map data) {
  final contents = data['contents'];
  if (contents is! Map || !contents.containsKey('tabbedSearchResultsRenderer')) {
    throw const InnerTubeChanged('no tabbedSearchResultsRenderer');
  }
  final out = <YtmArtistRef>[];
  for (final item in collectRenderers(contents, 'musicResponsiveListItemRenderer')) {
    final nav = _asRun(item['navigationEndpoint']);
    final id = browseIdOf(nav);
    if (pageTypeOf(nav) != _artistType || id == null) continue;
    final columns = _columns(item);
    final name = columns.isEmpty ? '' : runsText(columns[0]);
    if (name.isEmpty) continue;
    out.add(YtmArtistRef(
      id: id,
      name: htmlUnescape(name),
      thumbnailUrl: pickThumbnail(item['thumbnail']),
      audience: columns.length > 1 ? _audience(columns[1]) : null,
    ));
  }
  return out;
}

List<Object?> _columns(Map item) => [
      for (final c in item['flexColumns'] is List ? item['flexColumns'] as List : const [])
        if (c is Map && c['musicResponsiveListItemFlexColumnRenderer'] is Map)
          (c['musicResponsiveListItemFlexColumnRenderer'] as Map)['text'],
    ];

/// One song row of a shelf or list: title with the video, credited artists in
/// the second column (linked ones carry their page id), the album in any
/// column, the length in the fixed column. Null when the row has no video.
YtResult? parseSongRow(
  Map item, {
  YtmArtistRef? defaultArtist,
  String? defaultAlbum,
  String? defaultAlbumId,
  String? defaultThumbnail,
}) {
  final columns = _columns(item);
  if (columns.isEmpty) return null;
  final data = item['playlistItemData'];
  var id = data is Map && data['videoId'] is String ? data['videoId'] as String : null;
  final titleRuns = columns[0] is Map ? (columns[0] as Map)['runs'] : null;
  for (final r in id != null || titleRuns is! List ? const [] : titleRuns) {
    final watch = r is Map && r['navigationEndpoint'] is Map
        ? (r['navigationEndpoint'] as Map)['watchEndpoint']
        : null;
    if (watch is Map && watch['videoId'] is String) id = watch['videoId'] as String;
  }
  final title = runsText(columns[0]);
  if (id == null || title.isEmpty) return null;

  final artists = <String>[], artistIds = <String>[];
  if (columns.length > 1) {
    final runs = columns[1] is Map ? (columns[1] as Map)['runs'] : null;
    for (final r in runs is List ? runs : const []) {
      if (r is! Map || r['text'] is! String) continue;
      final name = (r['text'] as String).trim();
      if (name.isEmpty || artistJoiners.contains(name.toLowerCase())) continue;
      artists.add(htmlUnescape(name));
      artistIds.add(pageTypeOf(r) == _artistType ? browseIdOf(r) ?? '' : '');
    }
  }
  if (artists.isEmpty && defaultArtist != null) {
    artists.add(defaultArtist.name);
    artistIds.add(defaultArtist.id);
  }

  String? album = defaultAlbum, albumId = defaultAlbumId;
  for (final c in columns.skip(1)) {
    final runs = c is Map ? c['runs'] : null;
    for (final r in runs is List ? runs : const []) {
      if (pageTypeOf(r) == _albumType) {
        album = htmlUnescape((r as Map)['text'] as String);
        albumId = browseIdOf(r);
      }
    }
  }

  Duration? duration;
  final fixed = item['fixedColumns'];
  if (fixed is List && fixed.isNotEmpty && fixed.first is Map) {
    final col = (fixed.first as Map)['musicResponsiveListItemFixedColumnRenderer'];
    if (col is Map) duration = parseClock(runsText(col['text']));
  }
  return YtResult(
    id: id,
    title: htmlUnescape(title),
    channel: artists.isEmpty ? '' : artists.first,
    duration: duration,
    thumbnailUrl:
        pickThumbnail(item['thumbnail']) ?? defaultThumbnail ?? smallVideoThumbnail(id),
    artists: artists,
    album: album,
    artistIds: artistIds,
    albumId: albumId,
  );
}

/// An album/single/EP tile of a carousel or grid; null for any other kind.
YtmRelease? parseReleaseTile(Map tile) {
  final nav = _asRun(tile['navigationEndpoint']);
  final id = browseIdOf(nav);
  final title = runsText(tile['title']);
  if (pageTypeOf(nav) != _albumType || id == null || title.isEmpty) return null;
  return YtmRelease(
    browseId: id,
    title: htmlUnescape(title),
    subtitle: runsText(tile['subtitle']),
    thumbnailUrl: pickThumbnail(tile['thumbnailRenderer'], minWidth: 226),
  );
}

YtmBrowseLink? _linkOf(Object? run) {
  final id = browseIdOf(run);
  if (id == null) return null;
  final browse = ((run as Map)['navigationEndpoint'] as Map)['browseEndpoint'] as Map;
  return YtmBrowseLink(id, browse['params'] as String?);
}

/// An artist page (`browse` of a `UC…` id). Sections are recognised by the kind
/// of their items, never by their titles (YouTube translates them): a shelf of
/// songs, a carousel of albums, a carousel of artists, the description.
/// Videos, episodes, podcasts and playlists are left out.
YtmArtistPage parseArtistPage(Map data, String id) {
  final contents = data['contents'], header = data['header'];
  if (contents is! Map && header is! Map) throw ArtistNotFound(id);
  final head = header is Map
      ? (header['musicImmersiveHeaderRenderer'] ?? header['musicVisualHeaderRenderer'])
      : null;
  if (head is! Map) throw const InnerTubeChanged('no artist header');
  if (contents is! Map || contents['singleColumnBrowseResultsRenderer'] is! Map) {
    throw const InnerTubeChanged('no singleColumnBrowseResultsRenderer');
  }
  final name = htmlUnescape(runsText(head['title']));
  if (name.isEmpty) throw const InnerTubeChanged('artist without a name');

  final shelves = <YtmShelf>[];
  var description = runsText(head['description']);
  for (final section in collectRenderers(contents, 'sectionListRenderer')
      .expand((l) => l['contents'] is List ? l['contents'] as List : const [])) {
    if (section is! Map) continue;
    final shelf = section['musicShelfRenderer'];
    final carousel = section['musicCarouselShelfRenderer'];
    final about = section['musicDescriptionShelfRenderer'];
    if (shelf is Map) {
      final songs = <YtResult>[
        for (final r in collectRenderers(shelf['contents'], 'musicResponsiveListItemRenderer'))
          ?parseSongRow(r),
      ];
      if (songs.isEmpty) continue;
      final titleRuns = shelf['title'] is Map ? (shelf['title'] as Map)['runs'] : null;
      shelves.add(YtmSongShelf(
        runsText(shelf['title']),
        songs,
        allSongs: _linkOf(titleRuns is List && titleRuns.isNotEmpty ? titleRuns.first : null),
      ));
    } else if (carousel is Map) {
      final s = _carousel(carousel);
      if (s != null) shelves.add(s);
    } else if (about is Map && description.isEmpty) {
      description = runsText(about['description']);
    }
  }

  return YtmArtistPage(
    ref: YtmArtistRef(
      id: id,
      name: name,
      audience: runsText(head['monthlyListenerCount']).trim().isEmpty
          ? null
          : runsText(head['monthlyListenerCount']).trim(),
    ),
    description: description.isEmpty ? null : description,
    shelves: shelves,
    radio: _radio(head['startRadioButton']),
  );
}

YtmShelf? _carousel(Map carousel) {
  final header = carousel['header'] is Map
      ? (carousel['header'] as Map)['musicCarouselShelfBasicHeaderRenderer']
      : null;
  final title = header is Map ? runsText(header['title']) : '';
  final tiles = collectRenderers(carousel['contents'], 'musicTwoRowItemRenderer');
  final releases = [for (final t in tiles) ?parseReleaseTile(t)];
  if (releases.isNotEmpty) {
    final more = header is Map && header['moreContentButton'] is Map
        ? ((header['moreContentButton'] as Map)['buttonRenderer'] as Map?)
        : null;
    return YtmReleaseShelf(title, releases, more: _linkOf(more));
  }
  final artists = <YtmArtistRef>[];
  for (final t in tiles) {
    final nav = _asRun(t['navigationEndpoint']);
    final id = browseIdOf(nav), name = runsText(t['title']);
    if (pageTypeOf(nav) != _artistType || id == null || name.isEmpty) continue;
    artists.add(YtmArtistRef(
      id: id,
      name: htmlUnescape(name),
      thumbnailUrl: pickThumbnail(t['thumbnailRenderer']),
      audience: runsText(t['subtitle']).isEmpty ? null : runsText(t['subtitle']),
    ));
  }
  return artists.isEmpty ? null : YtmArtistShelf(title, artists);
}

YtmWatchLink? _radio(Object? button) {
  final b = button is Map ? button['buttonRenderer'] : null;
  final nav = b is Map ? b['navigationEndpoint'] : null;
  final watch = nav is Map ? nav['watchEndpoint'] : null;
  if (watch is! Map) return null;
  return YtmWatchLink(
    videoId: watch['videoId'] as String?,
    playlistId: watch['playlistId'] as String?,
    params: watch['params'] as String?,
  );
}
