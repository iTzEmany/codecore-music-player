import 'package:drift/drift.dart';

import '../db/app_database.dart';

enum AlbumSort { title, artist, year }

class AlbumSummary {
  const AlbumSummary({
    required this.albumKey,
    required this.title,
    required this.artist,
    required this.variousArtists,
    required this.trackCount,
    required this.durationMs,
    required this.year,
    required this.coverKey,
  });

  final String albumKey;
  final String? title; // null = unknown album
  final String? artist;
  final bool variousArtists;
  final int trackCount, durationMs;
  final int? year;
  final String? coverKey;
}

class ArtistSummary {
  const ArtistSummary({
    required this.key,
    required this.name,
    required this.trackCount,
    required this.albumCount,
  });

  final String key; // lowercase trimmed; '' = unknown artist
  final String? name;
  final int trackCount, albumCount;
}

const _albumSelect = '''
SELECT album_key,
  MIN(album) AS album,
  MAX(album_artist) AS album_artist,
  MIN(artist) AS artist,
  COUNT(DISTINCT lower(trim(COALESCE(artist, '')))) AS artist_count,
  COUNT(*) AS track_count,
  SUM(duration_ms) AS duration_ms,
  MAX(year) AS year,
  MIN(cover_key) AS cover_key
FROM tracks
''';

class LibraryQueries {
  LibraryQueries(this._db);

  final AppDatabase _db;

  AlbumSummary _album(QueryRow r) {
    final albumArtist = r.read<String?>('album_artist');
    final count = r.read<int>('artist_count');
    return AlbumSummary(
      albumKey: r.read<String>('album_key'),
      title: r.read<String?>('album'),
      artist: albumArtist ?? r.read<String?>('artist'),
      variousArtists: albumArtist == null && count > 1,
      trackCount: r.read<int>('track_count'),
      durationMs: r.read<int?>('duration_ms') ?? 0,
      year: r.read<int?>('year'),
      coverKey: r.read<String?>('cover_key'),
    );
  }

  Stream<List<AlbumSummary>> watchAlbums({AlbumSort sort = AlbumSort.title}) {
    final order = switch (sort) {
      AlbumSort.title => 'album COLLATE NOCASE',
      AlbumSort.artist => 'COALESCE(album_artist, artist) COLLATE NOCASE, album COLLATE NOCASE',
      AlbumSort.year => 'year DESC, album COLLATE NOCASE',
    };
    return _db
        .customSelect(
          '$_albumSelect WHERE missing = 0 GROUP BY album_key ORDER BY $order',
          readsFrom: {_db.tracks},
        )
        .watch()
        .map((rows) => rows.map(_album).toList());
  }

  Stream<List<AlbumSummary>> watchArtistAlbums(String artistKey) {
    return _db
        .customSelect(
          '$_albumSelect WHERE missing = 0 AND album_key IN ('
          "SELECT album_key FROM tracks WHERE missing = 0 AND lower(trim(COALESCE(artist, ''))) = ?) "
          'GROUP BY album_key ORDER BY year DESC, album COLLATE NOCASE',
          variables: [Variable<String>(artistKey)],
          readsFrom: {_db.tracks},
        )
        .watch()
        .map((rows) => rows.map(_album).toList());
  }

  Stream<List<ArtistSummary>> watchArtists() {
    return _db
        .customSelect(
          "SELECT lower(trim(COALESCE(artist, ''))) AS k, MIN(artist) AS name, "
          'COUNT(*) AS track_count, COUNT(DISTINCT album_key) AS album_count '
          'FROM tracks WHERE missing = 0 GROUP BY k ORDER BY k COLLATE NOCASE',
          readsFrom: {_db.tracks},
        )
        .watch()
        .map((rows) => [
              for (final r in rows)
                ArtistSummary(
                  key: r.read<String>('k'),
                  name: r.read<String?>('name'),
                  trackCount: r.read<int>('track_count'),
                  albumCount: r.read<int>('album_count'),
                ),
            ]);
  }

  Stream<List<Track>> watchAlbumTracks(String albumKey) {
    return (_db.select(_db.tracks)
          ..where((t) => t.albumKey.equals(albumKey) & t.missing.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.discNumber),
            (t) => OrderingTerm.asc(t.trackNumber),
            (t) => OrderingTerm(
                expression: t.title.collate(Collate.noCase)),
          ]))
        .watch();
  }
}
