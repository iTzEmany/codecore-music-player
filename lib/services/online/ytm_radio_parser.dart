import '../../core/text_utils.dart';
import 'innertube_client.dart' show InnerTubeChanged;
import 'innertube_json.dart';
import 'youtube_service.dart';

/// What a radio row is, from the page its byline links to.
enum RadioKind {
  /// A YouTube Music song (its byline names an album).
  song,

  /// A video on an artist's channel (no album).
  artistVideo,

  /// An upload by a user: never suggested.
  upload,
}

class RadioItem {
  const RadioItem(this.result, this.kind, {this.isSeed = false});

  final YtResult result;
  final RadioKind kind;

  /// The song the radio was started from (first row, `selected`).
  final bool isSeed;
}

class RadioPage {
  const RadioPage(this.items, {this.continuation});

  const RadioPage.empty()
      : items = const [],
        continuation = null;

  final List<RadioItem> items;

  /// Asks for the next page of the same radio; null at the end.
  final String? continuation;
}

/// Field mask of the first radio page (and of the continuations below).
const radioMask = 'contents.singleColumnMusicWatchNextResultsRenderer.tabbedRenderer'
    '.watchNextTabbedResultsRenderer.tabs.tabRenderer.content.musicQueueRenderer'
    '(content.playlistPanelRenderer(contents.playlistPanelVideoRenderer'
    '(videoId,title,longBylineText,lengthText,thumbnail,selected),continuations))';
const radioContinuationMask = 'continuationContents.playlistPanelContinuation'
    '(contents.playlistPanelVideoRenderer(videoId,title,longBylineText,lengthText,thumbnail,selected),'
    'continuations)';

/// The first page of a radio (`next` answer). A known answer without rows is
/// a real «nothing»; an unknown one throws [InnerTubeChanged].
RadioPage parseRadio(Map data) {
  final contents = data['contents'];
  if (contents is! Map || contents['singleColumnMusicWatchNextResultsRenderer'] is! Map) {
    throw const InnerTubeChanged('no singleColumnMusicWatchNextResultsRenderer');
  }
  final panels = collectRenderers(contents, 'playlistPanelRenderer');
  if (panels.isEmpty) throw const InnerTubeChanged('no playlistPanelRenderer');
  return _page(panels.first, firstPage: true);
}

/// A later page of the same radio (`continuationContents`).
RadioPage parseRadioContinuation(Map data) {
  final cont = data['continuationContents'];
  final panel = cont is Map ? cont['playlistPanelContinuation'] : null;
  if (panel is! Map) throw const InnerTubeChanged('no playlistPanelContinuation');
  return _page(panel, firstPage: false);
}

RadioPage _page(Map panel, {required bool firstPage}) {
  final items = <RadioItem>[];
  final rows = panel['contents'];
  for (final entry in rows is List ? rows : const []) {
    final row = _rowOf(entry);
    if (row == null) continue;
    final item = _item(row, firstRow: firstPage && items.isEmpty);
    if (item != null) items.add(item);
  }
  return RadioPage(items, continuation: _continuationOf(panel));
}

/// Rows with a video and its audio-only twin come wrapped: the primary one.
Map? _rowOf(Object? entry) {
  if (entry is! Map) return null;
  final direct = entry['playlistPanelVideoRenderer'];
  if (direct is Map) return direct;
  final wrapper = entry['playlistPanelVideoWrapperRenderer'];
  final primary = wrapper is Map ? wrapper['primaryRenderer'] : null;
  final inner = primary is Map ? primary['playlistPanelVideoRenderer'] : null;
  return inner is Map ? inner : null;
}

String? _continuationOf(Map panel) {
  final list = panel['continuations'];
  for (final c in list is List ? list : const []) {
    final next = c is Map ? c['nextRadioContinuationData'] : null;
    final token = next is Map ? next['continuation'] : null;
    if (token is String && token.isNotEmpty) return token;
  }
  return null;
}

RadioItem? _item(Map row, {required bool firstRow}) {
  final id = row['videoId'];
  final title = htmlUnescape(runsText(row['title']));
  if (id is! String || id.isEmpty || title.isEmpty) return null;

  final groups = bulletGroups(row['longBylineText']);
  final artists = <String>[];
  final artistIds = <String>[];
  var firstType = '';
  if (groups.isNotEmpty) {
    for (final r in groups.first) {
      final name = (r['text'] as String).trim();
      if (name.isEmpty || artistJoiners.contains(name.toLowerCase())) continue;
      final type = pageTypeOf(r);
      if (firstType.isEmpty && type != null) firstType = type;
      artists.add(htmlUnescape(name));
      artistIds.add(type == 'MUSIC_PAGE_TYPE_ARTIST' ? browseIdOf(r) ?? '' : '');
    }
  }
  String? album, albumId;
  for (final g in groups.skip(1)) {
    for (final r in g) {
      if (pageTypeOf(r) == 'MUSIC_PAGE_TYPE_ALBUM') {
        album = htmlUnescape((r['text'] as String).trim());
        albumId = browseIdOf(r);
      }
    }
  }

  final kind = album != null
      ? RadioKind.song
      : firstType == 'MUSIC_PAGE_TYPE_ARTIST'
          ? RadioKind.artistVideo
          : RadioKind.upload;
  final isSong = kind == RadioKind.song;
  return RadioItem(
    YtResult(
      id: id,
      title: title,
      channel: artists.isEmpty ? '' : artists.first,
      duration: parseClock(runsText(row['lengthText'])),
      thumbnailUrl: pickThumbnail(row) ?? smallVideoThumbnail(id),
      // The «artists» of a video row are its channel, not credited artists.
      artists: isSong ? artists : const [],
      artistIds: isSong ? artistIds : const [],
      album: album,
      albumId: albumId,
    ),
    kind,
    isSeed: row['selected'] == true || (firstRow && row['selected'] == null && isSong),
  );
}

/// yt-dlp's mix listing as a radio: it has no album, so every row is at best
/// an artist video.
List<RadioItem> radioFromListing(PlaylistListing listing, {String? seedId}) => [
      for (final e in listing.entries)
        RadioItem(e, RadioKind.artistVideo, isSeed: e.id == seedId),
    ];
