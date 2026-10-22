// Reading the address a user types in to add a radio by hand (33.10). Pure:
// the download of a playlist file is passed in, so nothing here touches the
// network.

/// A playlist file bigger than this is refused.
const kMaxPlaylistBytes = 64 * 1024;

enum StreamLinkError {
  /// Nothing typed.
  empty,

  /// Not an address at all.
  notAnAddress,

  /// An address, but not http or https.
  badScheme,

  /// A playlist file with no http(s) address inside.
  noEntries,

  /// A playlist file over [kMaxPlaylistBytes].
  tooBig,

  /// The playlist file could not be downloaded.
  fetchFailed,
}

class StreamLinkException implements Exception {
  const StreamLinkException(this.reason);
  final StreamLinkError reason;

  @override
  String toString() => 'StreamLinkException($reason)';
}

/// What a typed address is.
sealed class StreamLink {
  const StreamLink(this.url);
  final String url;
}

/// An address to play as it is.
class DirectLink extends StreamLink {
  const DirectLink(super.url);
}

/// A `.pls` or `.m3u` file: the stream address is inside it.
class PlaylistLink extends StreamLink {
  const PlaylistLink(super.url);
}

/// Checks [text] and says what it is. Throws [StreamLinkException].
StreamLink parseStreamLink(String text) {
  final t = text.trim();
  if (t.isEmpty) throw const StreamLinkException(StreamLinkError.empty);
  final uri = Uri.tryParse(t);
  if (uri == null || t.contains(RegExp(r'\s'))) {
    throw const StreamLinkException(StreamLinkError.notAnAddress);
  }
  if (!uri.hasScheme) throw const StreamLinkException(StreamLinkError.notAnAddress);
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    throw const StreamLinkException(StreamLinkError.badScheme);
  }
  if (uri.host.isEmpty) throw const StreamLinkException(StreamLinkError.notAnAddress);
  final path = uri.path.toLowerCase();
  // `.m3u8` is an HLS stream the player reads itself, not a list.
  if (path.endsWith('.pls') || path.endsWith('.m3u')) return PlaylistLink(t);
  return DirectLink(t);
}

/// The first http(s) address in the text of a `.pls` or `.m3u` file, or null.
/// Comments (`#...`), blank lines and relative entries are skipped.
String? firstStreamInPlaylist(String body) {
  for (final raw in body.split(RegExp(r'\r\n|\r|\n'))) {
    var line = raw.trim();
    if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) continue;
    final pls = RegExp(r'^file\d*\s*=\s*(.*)$', caseSensitive: false).firstMatch(line);
    if (pls != null) {
      line = pls.group(1)!.trim();
    } else if (line.contains('=') && !line.toLowerCase().startsWith('http')) {
      continue; // another key of a .pls ([playlist], Title1=, Length1=...)
    }
    if (_isHttp(line)) return line;
  }
  return null;
}

bool _isHttp(String s) {
  final u = Uri.tryParse(s);
  return u != null &&
      (u.scheme.toLowerCase() == 'http' || u.scheme.toLowerCase() == 'https') &&
      u.host.isNotEmpty;
}

/// The address to play for the typed [text]: itself, or the first entry of the
/// playlist file that [fetch] downloads. Throws [StreamLinkException].
Future<String> resolveStreamLink(String text, Future<String> Function(Uri url) fetch) async {
  final link = parseStreamLink(text);
  if (link is DirectLink) return link.url;
  final String body;
  try {
    body = await fetch(Uri.parse(link.url));
  } on StreamLinkException {
    rethrow;
  } on Object {
    throw const StreamLinkException(StreamLinkError.fetchFailed);
  }
  if (body.length > kMaxPlaylistBytes) {
    throw const StreamLinkException(StreamLinkError.tooBig);
  }
  final first = firstStreamInPlaylist(body);
  if (first == null) throw const StreamLinkException(StreamLinkError.noEntries);
  return first;
}
