/// Readers for the YouTube Music «Testo» (lyrics) tab: the `next` answer of a
/// song names the page, the `browse` answer of that page holds the text.
library;

import 'innertube_json.dart';

/// The browse id of the «Testo» tab (`MPLY…`), null when the song has none.
String? lyricsBrowseId(Map next) {
  for (final tab in collectRenderers(next, 'tabRenderer')) {
    final id = browseIdOf(tab['endpoint'] == null ? null : {'navigationEndpoint': tab['endpoint']});
    if (id != null && id.startsWith('MPLY')) return id;
  }
  return null;
}

/// The plain text of the lyrics page, `\n`-separated; null when it has fewer
/// than 3 non-empty lines. The «Fonte: …» footer is not part of it.
String? parseLyrics(Map browse) {
  final shelf = collectRenderers(browse, 'musicDescriptionShelfRenderer').firstOrNull;
  if (shelf == null) return null;
  final text = runsText(shelf['description']).replaceAll('\r\n', '\n').trim();
  return text.split('\n').where((l) => l.trim().isNotEmpty).length < 3 ? null : text;
}
