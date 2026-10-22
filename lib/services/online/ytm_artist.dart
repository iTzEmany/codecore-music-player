import 'search_cache.dart' show ytResultFromJson, ytResultToJson;
import 'youtube_service.dart';

/// An artist as search and «Fans might also like» list it.
class YtmArtistRef {
  const YtmArtistRef({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.audience,
  });

  /// `UC…` channel id, the `browseId` of the artist page.
  final String id, name;

  /// Square photo; null where the page only has a wide banner.
  final String? thumbnailUrl;

  /// «25.9M monthly audience», in the language asked for.
  final String? audience;

  Map<String, Object?> toJson() =>
      {'id': id, 'name': name, 'thumb': thumbnailUrl, 'audience': audience};

  static YtmArtistRef? fromJson(Object? j) {
    if (j is! Map || j['id'] is! String || j['name'] is! String) return null;
    return YtmArtistRef(
      id: j['id'] as String,
      name: j['name'] as String,
      thumbnailUrl: j['thumb'] as String?,
      audience: j['audience'] as String?,
    );
  }
}

/// A `browse` request that continues a section («show all», discography).
class YtmBrowseLink {
  const YtmBrowseLink(this.browseId, this.params);

  final String browseId;
  final String? params;

  Map<String, Object?> toJson() => {'id': browseId, 'params': params};

  static YtmBrowseLink? fromJson(Object? j) {
    if (j is! Map || j['id'] is! String) return null;
    return YtmBrowseLink(j['id'] as String, j['params'] as String?);
  }
}

/// A `watchEndpoint` (the artist's «Mix» radio).
class YtmWatchLink {
  const YtmWatchLink({this.videoId, this.playlistId, this.params});

  final String? videoId, playlistId, params;

  Map<String, Object?> toJson() =>
      {'v': videoId, 'list': playlistId, 'params': params};

  static YtmWatchLink? fromJson(Object? j) => j is! Map
      ? null
      : YtmWatchLink(
          videoId: j['v'] as String?,
          playlistId: j['list'] as String?,
          params: j['params'] as String?,
        );
}

/// An album, single or EP in a carousel or the discography.
class YtmRelease {
  const YtmRelease({
    required this.browseId,
    required this.title,
    required this.subtitle,
    this.thumbnailUrl,
  });

  /// `MPREb_…`.
  final String browseId, title;

  /// «EP • 2025», «2026»: as YouTube writes it.
  final String subtitle;
  final String? thumbnailUrl;

  Map<String, Object?> toJson() =>
      {'id': browseId, 'title': title, 'sub': subtitle, 'thumb': thumbnailUrl};

  static YtmRelease? fromJson(Object? j) {
    if (j is! Map || j['id'] is! String || j['title'] is! String) return null;
    return YtmRelease(
      browseId: j['id'] as String,
      title: j['title'] as String,
      subtitle: '${j['sub'] ?? ''}',
      thumbnailUrl: j['thumb'] as String?,
    );
  }
}

/// A section of the artist page, recognised by the kind of its items.
sealed class YtmShelf {
  const YtmShelf(this.title);

  /// Heading as YouTube gives it, already in the language asked for.
  final String title;

  Map<String, Object?> toJson();

  static YtmShelf? fromJson(Object? j) {
    if (j is! Map) return null;
    final title = '${j['title'] ?? ''}';
    List<T> list<T>(T? Function(Object?) read) =>
        [for (final x in j['items'] is List ? j['items'] as List : const []) ?read(x)];
    return switch (j['type']) {
      'songs' => YtmSongShelf(title, list(ytResultFromJson),
          allSongs: YtmBrowseLink.fromJson(j['link'])),
      'releases' => YtmReleaseShelf(title, list(YtmRelease.fromJson),
          more: YtmBrowseLink.fromJson(j['link'])),
      'artists' => YtmArtistShelf(title, list(YtmArtistRef.fromJson)),
      _ => null,
    };
  }
}

/// «Top songs»: a few songs (no length) and the link to the full list.
class YtmSongShelf extends YtmShelf {
  const YtmSongShelf(super.title, this.songs, {this.allSongs});

  final List<YtResult> songs;
  final YtmBrowseLink? allSongs;

  @override
  Map<String, Object?> toJson() => {
        'type': 'songs',
        'title': title,
        'items': [for (final s in songs) ytResultToJson(s)],
        'link': allSongs?.toJson(),
      };
}

/// A group of albums, or of singles and EPs; [more] opens the discography.
class YtmReleaseShelf extends YtmShelf {
  const YtmReleaseShelf(super.title, this.releases, {this.more});

  final List<YtmRelease> releases;
  final YtmBrowseLink? more;

  @override
  Map<String, Object?> toJson() => {
        'type': 'releases',
        'title': title,
        'items': [for (final r in releases) r.toJson()],
        'link': more?.toJson(),
      };
}

/// «Fans might also like».
class YtmArtistShelf extends YtmShelf {
  const YtmArtistShelf(super.title, this.artists);

  final List<YtmArtistRef> artists;

  @override
  Map<String, Object?> toJson() => {
        'type': 'artists',
        'title': title,
        'items': [for (final a in artists) a.toJson()],
      };
}

class YtmArtistPage {
  const YtmArtistPage({
    required this.ref,
    required this.shelves,
    this.description,
    this.radio,
  });

  /// Name, id and monthly audience; no photo (the page only has a banner).
  final YtmArtistRef ref;
  final String? description;
  final List<YtmShelf> shelves;

  /// The «Mix» button; not used before the radio phase.
  final YtmWatchLink? radio;

  Map<String, Object?> toJson() => {
        'ref': ref.toJson(),
        'desc': description,
        'shelves': [for (final s in shelves) s.toJson()],
        'radio': radio?.toJson(),
      };

  static YtmArtistPage? fromJson(Object? j) {
    if (j is! Map) return null;
    final ref = YtmArtistRef.fromJson(j['ref']);
    if (ref == null) return null;
    return YtmArtistPage(
      ref: ref,
      description: j['desc'] as String?,
      shelves: [
        for (final s in j['shelves'] is List ? j['shelves'] as List : const [])
          ?YtmShelf.fromJson(s),
      ],
      radio: YtmWatchLink.fromJson(j['radio']),
    );
  }
}

/// One row of an album: its place on the record and the song.
class YtmAlbumTrack {
  const YtmAlbumTrack(this.number, this.result);

  /// 1-based position; null when the source gave none.
  final int? number;
  final YtResult result;
}

class YtmAlbum {
  const YtmAlbum({
    required this.browseId,
    required this.title,
    required this.tracks,
    this.artist,
    this.year,
    this.kindLabel,
    this.coverUrl,
  });

  final String browseId, title;
  final YtmArtistRef? artist;
  final String? year;

  /// «Album», «EP», «Single» as YouTube writes it (translated by `hl`).
  final String? kindLabel;
  final String? coverUrl;
  final List<YtmAlbumTrack> tracks;

  Map<String, Object?> toJson() => {
        'id': browseId,
        'title': title,
        'artist': artist?.toJson(),
        'year': year,
        'kind': kindLabel,
        'cover': coverUrl,
        'tracks': [
          for (final t in tracks) {'n': t.number, 'r': ytResultToJson(t.result)},
        ],
      };

  static YtmAlbum? fromJson(Object? j) {
    if (j is! Map || j['id'] is! String || j['title'] is! String) return null;
    final tracks = <YtmAlbumTrack>[];
    for (final t in j['tracks'] is List ? j['tracks'] as List : const []) {
      final r = t is Map ? ytResultFromJson(t['r']) : null;
      if (r != null) tracks.add(YtmAlbumTrack((t as Map)['n'] as int?, r));
    }
    return YtmAlbum(
      browseId: j['id'] as String,
      title: j['title'] as String,
      artist: YtmArtistRef.fromJson(j['artist']),
      year: j['year'] as String?,
      kindLabel: j['kind'] as String?,
      coverUrl: j['cover'] as String?,
      tracks: tracks,
    );
  }
}

/// The «top result» card of an unfiltered YouTube Music search.
sealed class TopCard {
  const TopCard();
}

class TopArtist extends TopCard {
  const TopArtist(this.artist);

  final YtmArtistRef artist;
}

/// An album; [artist] is the one the card credits, when it links to a page.
class TopAlbum extends TopCard {
  const TopAlbum(this.release, this.artist);

  final YtmRelease release;
  final YtmArtistRef? artist;
}

/// A song of the catalog (`MUSIC_VIDEO_TYPE_ATV`), not a video clip.
class TopSong extends TopCard {
  const TopSong(this.videoId, this.title);

  final String videoId, title;
}

/// Any other playable card: a music video, a live recording, an upload.
class TopVideo extends TopCard {
  const TopVideo(this.videoId, this.title);

  final String videoId, title;
}
