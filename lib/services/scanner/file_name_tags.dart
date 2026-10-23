/// Splits a file name (no extension) like "Artist - Title (Official Video)"
/// into artist and title. Without a usable split the whole name is the title.
({String artist, String title}) splitArtistTitle(String baseName) {
  final name = baseName.replaceAll(_junk, '').trim();
  final m = _separator.firstMatch(name);
  if (m != null) {
    final artist = name.substring(0, m.start).trim();
    final title = name.substring(m.end).trim();
    if (artist.isNotEmpty && title.isNotEmpty) {
      return (artist: artist, title: title);
    }
  }
  return (artist: '', title: name.isEmpty ? baseName : name);
}

final _separator = RegExp(r' [-–—] ');
final _junk = RegExp(
  r'\s*[(\[](official (music )?video|official audio|lyrics?|lyric video|hd|hq|audio)[)\]]',
  caseSensitive: false,
);
