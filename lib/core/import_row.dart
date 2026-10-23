/// One track of the CSV, in playlist order.
class ImportRow {
  const ImportRow({
    required this.index,
    required this.title,
    required this.artists,
    this.album,
    this.durationMs,
    this.isrc,
    this.spotifyUri,
    this.location,
    this.trackNumber,
    this.year,
  });

  final int index;
  final String title;
  final List<String> artists;
  final String? album;
  final int? durationMs;
  final String? isrc;
  final String? spotifyUri;

  /// Path or URL of a local M3U/XSPF entry, tried against the library first.
  final String? location;

  /// Place on the record, set for the rows of an online album import only.
  final int? trackNumber;

  /// Release year from the CSV `Release Date`, when it has a valid one.
  final int? year;

  ImportRow withLocation(String? location) => ImportRow(
        index: index,
        title: title,
        artists: artists,
        album: album,
        durationMs: durationMs,
        isrc: isrc,
        spotifyUri: spotifyUri,
        location: location,
        trackNumber: trackNumber,
        year: year,
      );

  ImportRow withTrackNumber(int? n) => ImportRow(
        index: index,
        title: title,
        artists: artists,
        album: album,
        durationMs: durationMs,
        isrc: isrc,
        spotifyUri: spotifyUri,
        location: location,
        trackNumber: n,
        year: year,
      );

  String get primaryArtist => artists.isEmpty ? '' : artists.first;
  String get artistLine => artists.join(', ');
}

/// Library track as seen by the importer: loaded once, not once per row.
class LibraryEntryLite {
  const LibraryEntryLite({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationMs,
    this.path,
  });

  final int id;
  final String title;
  final String? artist;
  final int durationMs;

  /// Only filled where the path matters (backup restore).
  final String? path;
}
