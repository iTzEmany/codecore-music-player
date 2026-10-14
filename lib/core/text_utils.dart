const _diacritics = <String, String>{
  'àáâãäåāăą': 'a', 'ç': 'c', 'ćčĉċ': 'c', 'ďđ': 'd', 'èéêëēėęěĕ': 'e',
  'ĝğġ': 'g', 'ìíîïīĩįı': 'i', 'ñńňņ': 'n', 'òóôõöøōőŏ': 'o', 'ŕřŗ': 'r',
  'śšşŝș': 's', 'ťţț': 't', 'ùúûüūůűŭũų': 'u', 'ýÿŷ': 'y', 'źżž': 'z',
  'ß': 'ss', 'æ': 'ae', 'œ': 'oe', 'ł': 'l',
};

final Map<int, String> _diacriticMap = {
  for (final e in _diacritics.entries)
    for (final r in e.key.runes) r: e.value,
};

String stripDiacritics(String s) {
  final out = StringBuffer();
  for (final r in s.runes) {
    final lower = String.fromCharCode(r).toLowerCase().runes.first;
    final rep = _diacriticMap[lower];
    if (rep == null) {
      out.writeCharCode(r);
    } else {
      final isUpper = String.fromCharCode(r) != String.fromCharCode(r).toLowerCase();
      out.write(isUpper ? rep.toUpperCase() : rep);
    }
  }
  return out.toString();
}

String normalize(String s) =>
    stripDiacritics(s).toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

const _unknownAlbums = {'album sconosciuto', 'unknown', 'unknown album'};

String computeAlbumKey({
  String? albumArtist,
  String? artist,
  String? album,
  required String directory,
}) {
  final albumPart = normalize(album ?? '');
  if (albumPart.isEmpty || _unknownAlbums.contains(albumPart)) {
    return 'unknown|${normalize(directory)}';
  }
  final artistPart = normalize(albumArtist ?? artist ?? '');
  return '$artistPart|$albumPart';
}

final _illegalChars = RegExp(r'[\\/:*?"<>|%\u0000-\u001F]');
final _reserved = RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$',
    caseSensitive: false);

String sanitizeFileName(String name) {
  var s = name.replaceAll(_illegalChars, '');
  s = s.replaceAll(RegExp(r' {2,}'), ' ').trim();
  s = s.replaceAll(RegExp(r'[. ]+$'), '');
  s = s.replaceAll(RegExp(r'^\.+'), '');
  final dot = s.lastIndexOf('.');
  final stem = dot > 0 ? s.substring(0, dot) : s;
  if (_reserved.hasMatch(stem)) s = '_$s';
  final runes = s.runes.toList();
  if (runes.length > 120) s = String.fromCharCodes(runes.take(120));
  s = s.replaceAll(RegExp(r'[. ]+$'), '');
  return s.isEmpty ? 'track' : s;
}
