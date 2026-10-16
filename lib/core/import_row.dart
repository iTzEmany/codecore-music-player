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
  });

  final int index;
  final String title;
  final List<String> artists;
  final String? album;
  final int? durationMs;
  final String? isrc;
  final String? spotifyUri;

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
