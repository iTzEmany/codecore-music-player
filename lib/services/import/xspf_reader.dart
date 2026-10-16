import 'imported_playlist.dart';
import 'playlist_paths.dart';

final _trackBlock = RegExp(r'<track\b[^>]*>(.*?)</track>', dotAll: true);

String? _tag(String xml, String name) {
  final m = RegExp('<$name\\b[^>]*>(.*?)</$name>', dotAll: true).firstMatch(xml);
  if (m == null) return null;
  final v = _decode(m.group(1)!).trim();
  return v.isEmpty ? null : v;
}

final _entity = RegExp(r'&(#x[0-9a-fA-F]+|#\d+|amp|lt|gt|quot|apos);');

String _decode(String s) {
  var t = s.replaceAllMapped(
      RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true), (m) => m.group(1)!);
  t = t.replaceAllMapped(_entity, (m) {
    final e = m.group(1)!;
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
    return code == null || code > 0x10FFFF ? m.group(0)! : String.fromCharCode(code);
  });
  return t;
}

/// XSPF is read with a small tolerant parser limited to what a playlist
/// needs (`location`, `title`, `creator`, `album`, `duration` in ms).
ImportedPlaylist readXspf(String fileName, String text) {
  if (!text.contains('<trackList') && !_trackBlock.hasMatch(text)) {
    throw const FormatException('not an XSPF playlist');
  }
  final firstTrack = text.indexOf('<track');
  final head = firstTrack < 0 ? text : text.substring(0, firstTrack);
  final rows = <ImportRow>[];
  var skipped = 0;
  for (final m in _trackBlock.allMatches(text)) {
    final block = m.group(1)!;
    final location = _tag(block, 'location');
    final local = location == null ? null : localPathFromLocation(location);
    final title = _tag(block, 'title') ??
        (local == null ? null : withoutExtension(basenameOf(local)));
    if (title == null) {
      skipped++;
      continue;
    }
    final creator = _tag(block, 'creator');
    final ms = int.tryParse(_tag(block, 'duration') ?? '');
    rows.add(ImportRow(
      index: rows.length,
      title: title,
      artists: [?creator],
      album: _tag(block, 'album'),
      durationMs: ms != null && ms > 0 ? ms : null,
      location: local,
    ));
  }
  final name = _tag(head, 'title');
  final base = withoutExtension(basenameOf(fileName)).replaceAll('_', ' ').trim();
  return ImportedPlaylist(
    name: name ?? (base.isEmpty ? 'Playlist' : base),
    rows: rows,
    skipped: skipped,
    kind: 'xspf',
  );
}
