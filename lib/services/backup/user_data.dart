/// Portable user data: everything the user created, with tracks referenced by
/// relative path + title/artist/duration instead of the local DB id.
const kUserDataFormat = 1;

Map<String, Object?> _nonNull(Map<String, Object?> m) =>
    {for (final e in m.entries) if (e.value != null) e.key: e.value};

class TrackRef {
  const TrackRef({
    required this.title,
    this.folder,
    this.relPath,
    this.artist,
    this.durationMs = 0,
    this.sha256,
  });

  /// Root folder the track was found under. For a track outside every folder
  /// it holds the absolute file path and [relPath] is null.
  final String? folder;

  /// Path relative to [folder] (`/` separators).
  final String? relPath;
  final String title;
  final String? artist;
  final int durationMs;
  final String? sha256;

  Map<String, Object?> toJson() => _nonNull({
        'folder': folder,
        'relPath': relPath,
        'title': title,
        'artist': artist,
        'durationMs': durationMs,
        'sha256': sha256,
      });

  factory TrackRef.fromJson(Map<String, dynamic> j) => TrackRef(
        folder: j['folder'] as String?,
        relPath: j['relPath'] as String?,
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String?,
        durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
        sha256: j['sha256'] as String?,
      );
}

/// Title and tags the user changed by hand (`userEdited`).
class TrackEditData {
  const TrackEditData({
    required this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.year,
    this.trackNumber,
    this.genre,
  });

  final String title;
  final String? artist, album, albumArtist, genre;
  final int? year, trackNumber;

  Map<String, Object?> toJson() => _nonNull({
        'title': title,
        'artist': artist,
        'album': album,
        'albumArtist': albumArtist,
        'year': year,
        'trackNumber': trackNumber,
        'genre': genre,
      });

  factory TrackEditData.fromJson(Map<String, dynamic> j) => TrackEditData(
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String?,
        album: j['album'] as String?,
        albumArtist: j['albumArtist'] as String?,
        year: (j['year'] as num?)?.toInt(),
        trackNumber: (j['trackNumber'] as num?)?.toInt(),
        genre: j['genre'] as String?,
      );
}

class TrackUserData {
  const TrackUserData({
    required this.ref,
    this.favorite = false,
    this.edit,
    this.lyricsPlain,
    this.lyricsSynced,
    this.curiosities,
    this.playCount = 0,
    this.lastPlayedAt,
  });

  final TrackRef ref;
  final bool favorite;
  final TrackEditData? edit;
  final String? lyricsPlain, lyricsSynced, curiosities;
  final int playCount;
  final int? lastPlayedAt;

  Map<String, Object?> toJson() => _nonNull({
        'ref': ref.toJson(),
        'favorite': favorite ? true : null,
        'edit': edit?.toJson(),
        'lyricsPlain': lyricsPlain,
        'lyricsSynced': lyricsSynced,
        'curiosities': curiosities,
        'playCount': playCount == 0 ? null : playCount,
        'lastPlayedAt': lastPlayedAt,
      });

  factory TrackUserData.fromJson(Map<String, dynamic> j) => TrackUserData(
        ref: TrackRef.fromJson(j['ref'] as Map<String, dynamic>),
        favorite: j['favorite'] as bool? ?? false,
        edit: j['edit'] == null
            ? null
            : TrackEditData.fromJson(j['edit'] as Map<String, dynamic>),
        lyricsPlain: j['lyricsPlain'] as String?,
        lyricsSynced: j['lyricsSynced'] as String?,
        curiosities: j['curiosities'] as String?,
        playCount: (j['playCount'] as num?)?.toInt() ?? 0,
        lastPlayedAt: (j['lastPlayedAt'] as num?)?.toInt(),
      );
}

class PlaylistData {
  const PlaylistData({
    required this.name,
    required this.createdAt,
    this.coverKey,
    this.uuid,
    this.items = const [],
  });

  final String name;
  final int createdAt;
  final String? coverKey;

  /// Stable identity of the playlist (absent in older backups).
  final String? uuid;

  /// In playlist order.
  final List<TrackRef> items;

  Map<String, Object?> toJson() => _nonNull({
        'name': name,
        'createdAt': createdAt,
        'coverKey': coverKey,
        'uuid': uuid,
        'items': [for (final i in items) i.toJson()],
      });

  factory PlaylistData.fromJson(Map<String, dynamic> j) => PlaylistData(
        name: j['name'] as String? ?? '',
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
        coverKey: j['coverKey'] as String?,
        uuid: j['uuid'] as String?,
        items: [
          for (final i in (j['items'] as List? ?? const []))
            TrackRef.fromJson(i as Map<String, dynamic>),
        ],
      );
}

/// A CSV import and its rows. Kept for reference only: imports depend on the
/// downloads of the device that made them, so a restore never merges them.
class ImportData {
  const ImportData({
    required this.playlistName,
    required this.sourceName,
    required this.createdAt,
    required this.status,
    this.rows = const [],
  });

  final String playlistName, sourceName;
  final int createdAt, status;
  final List<ImportRowData> rows;

  Map<String, Object?> toJson() => {
        'playlistName': playlistName,
        'sourceName': sourceName,
        'createdAt': createdAt,
        'status': status,
        'rows': [for (final r in rows) r.toJson()],
      };

  factory ImportData.fromJson(Map<String, dynamic> j) => ImportData(
        playlistName: j['playlistName'] as String? ?? '',
        sourceName: j['sourceName'] as String? ?? '',
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
        status: (j['status'] as num?)?.toInt() ?? 0,
        rows: [
          for (final r in (j['rows'] as List? ?? const []))
            ImportRowData.fromJson(r as Map<String, dynamic>),
        ],
      );
}

class ImportRowData {
  const ImportRowData({
    required this.rowIndex,
    required this.title,
    required this.artists,
    required this.status,
    this.album,
    this.durationMs,
    this.isrc,
    this.videoId,
  });

  final int rowIndex, status;
  final String title, artists;
  final String? album, isrc, videoId;
  final int? durationMs;

  Map<String, Object?> toJson() => _nonNull({
        'rowIndex': rowIndex,
        'title': title,
        'artists': artists,
        'status': status,
        'album': album,
        'durationMs': durationMs,
        'isrc': isrc,
        'videoId': videoId,
      });

  factory ImportRowData.fromJson(Map<String, dynamic> j) => ImportRowData(
        rowIndex: (j['rowIndex'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? '',
        artists: j['artists'] as String? ?? '',
        status: (j['status'] as num?)?.toInt() ?? 0,
        album: j['album'] as String?,
        durationMs: (j['durationMs'] as num?)?.toInt(),
        isrc: j['isrc'] as String?,
        videoId: j['videoId'] as String?,
      );
}

class UserData {
  const UserData({
    required this.createdAt,
    this.tracks = const [],
    this.playlists = const [],
    this.imports = const [],
  });

  final int createdAt;
  final List<TrackUserData> tracks;
  final List<PlaylistData> playlists;
  final List<ImportData> imports;

  Map<String, Object?> toJson() => {
        'format': kUserDataFormat,
        'createdAt': createdAt,
        'tracks': [for (final t in tracks) t.toJson()],
        'playlists': [for (final p in playlists) p.toJson()],
        'imports': [for (final i in imports) i.toJson()],
      };

  /// Unknown fields are ignored; a newer `format` is refused.
  factory UserData.fromJson(Map<String, dynamic> j) {
    final format = (j['format'] as num?)?.toInt() ?? 0;
    if (format < 1 || format > kUserDataFormat) {
      throw FormatException('user_data format $format not supported');
    }
    return UserData(
      createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      tracks: [
        for (final t in (j['tracks'] as List? ?? const []))
          TrackUserData.fromJson(t as Map<String, dynamic>),
      ],
      playlists: [
        for (final p in (j['playlists'] as List? ?? const []))
          PlaylistData.fromJson(p as Map<String, dynamic>),
      ],
      imports: [
        for (final i in (j['imports'] as List? ?? const []))
          ImportData.fromJson(i as Map<String, dynamic>),
      ],
    );
  }
}
