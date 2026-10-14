import '../../core/text_utils.dart';

class CleanQuery {
  const CleanQuery(this.title, this.artist);

  final String title, artist;

  @override
  String toString() => 'CleanQuery($title | $artist)';
}

final _ext = RegExp(r'\.(mp3|m4a|flac|wav|ogg|aac|wma)$', caseSensitive: false);
final _prefix = RegExp(r'^(mix|audio|video|mashup)\s+', caseSensitive: false);
final _numbering = RegExp(r'^\d{1,3}[\s._-]+');
final _noiseGroup = RegExp(
    r'[\(\[\{][^\)\]\}]*(official|video|audio|remaster|hd|4k|hq|lyric|visualizer|clip|deluxe|bonus)[^\)\]\}]*[\)\]\}]',
    caseSensitive: false);
final _noisePhrase = RegExp(
    r'\b(official video|official audio|lyric video|4k remaster|remastered)\b',
    caseSensitive: false);
final _separator = RegExp(r' [-–—] ');
final _artistSuffix =
    RegExp(r'\s*(?:-\s*)?(official|vevo|topic)$', caseSensitive: false);

String _fixQuotes(String s) => s
    .replaceAll(RegExp('["“”`]'), '')
    .replaceAll('’', "'")
    .replaceAll('‘', "'");

bool _isGenericArtist(String artist) {
  final a = artist.trim().toLowerCase();
  return a.isEmpty ||
      a.contains('sconosciuto') ||
      a.contains('unknown') ||
      a.endsWith(' official') ||
      a.endsWith('vevo') ||
      a.endsWith(' - topic');
}

CleanQuery cleanSearchQuery(String rawTitle, String rawArtist) {
  var title = rawTitle.trim().replaceFirst(_ext, '');
  title = title.replaceFirst(_prefix, '');
  title = title.replaceFirst(_numbering, '');
  final genericArtist = _isGenericArtist(rawArtist);
  var artist = rawArtist.trim();

  title = title.replaceAll(_noiseGroup, ' ').replaceAll(_noisePhrase, ' ');
  title = _fixQuotes(title).replaceAll(RegExp(r'\s+'), ' ').trim();
  artist = _fixQuotes(artist);

  final m = _separator.firstMatch(title);
  if (m != null) {
    final a = title.substring(0, m.start).trim();
    final b = title.substring(m.end).trim();
    if (a.isNotEmpty && b.isNotEmpty) {
      if (genericArtist) {
        artist = a;
        title = b;
      } else if (normalize(a) == normalize(artist.replaceFirst(_artistSuffix, ''))) {
        title = b;
      }
    }
  }
  artist = artist.replaceFirst(_artistSuffix, '');
  return CleanQuery(title.trim(), artist.trim());
}

final _artistSplit =
    RegExp(r'\s*(?:,|&|/)\s*|\s+(?:feat|ft)\.?\s+', caseSensitive: false);

String extractPrimaryArtist(String artist) {
  final first = artist.split(_artistSplit).first.trim();
  return first.isEmpty ? artist : first;
}

final _coreNoise = RegExp(
    r'[\(\[\{][^\)\]\}]*(live|unplugged|acoustic|version|session|edit|from the series)[^\)\]\}]*[\)\]\}]',
    caseSensitive: false);

String coreTitle(String title) =>
    title.replaceAll(_coreNoise, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
