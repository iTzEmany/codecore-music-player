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
