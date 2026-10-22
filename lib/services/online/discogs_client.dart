import 'package:dio/dio.dart';

import 'http_client.dart';

/// Discogs, only for the notes of an album's *master* release (no key; the
/// notes of single releases speak of the packaging and are of no use).
class DiscogsClient {
  DiscogsClient(this._web);

  final WebClient _web;

  /// The notes of master [id] without Discogs' BBCode, null when there are none.
  Future<String?> master(int id, {CancelToken? cancel}) async {
    final data = await _web.getJson('https://api.discogs.com/masters/$id', cancel: cancel);
    final notes = data is Map ? data['notes'] : null;
    if (notes is! String) return null;
    final clean = stripBbcode(notes);
    return clean.isEmpty ? null : clean;
  }

  /// `[url=…]text[/url]` → text, `[a=Name]` → Name, bare ids (`[a123]`) and
  /// formatting tags (`[b]`, `[i]`…) vanish.
  static String stripBbcode(String s) => s
      .replaceAllMapped(RegExp(r'\[(?:a|l|r|m|url)=([^\]]*)\]'), (m) => m[0]!.startsWith('[url=') ? '' : m[1]!)
      .replaceAll(RegExp(r'\[/?[a-z]+\d*(?:=[^\]]*)?\]', caseSensitive: false), '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' ?\n ?'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
