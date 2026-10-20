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

final _spaces = RegExp(r'\s+');

String normalize(String s) =>
    stripDiacritics(s).toLowerCase().trim().replaceAll(_spaces, ' ');

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

final _entity = RegExp(r'&(#x[0-9a-fA-F]+|#\d+|amp|lt|gt|quot|apos);');

/// Decodes the HTML entities some yt-dlp listings leave in titles
/// (`Tom &amp; Jerry`). Anything that is not one of them stays as it is.
String htmlUnescape(String s) {
  if (!s.contains('&')) return s;
  return s.replaceAllMapped(_entity, (m) {
    final e = m[1]!;
    switch (e) {
      case 'amp':
        return '&';
      case 'lt':
        return '<';
      case 'gt':
        return '>';
      case 'quot':
        return '"';
      case 'apos':
        return "'";
    }
    final code = e.startsWith('#x')
        ? int.tryParse(e.substring(2), radix: 16)
        : int.tryParse(e.substring(1));
    if (code == null || code <= 0 || code > 0x10FFFF) return m[0]!;
    return String.fromCharCode(code);
  });
}
