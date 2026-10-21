/// Helpers shared by the InnerTube parsers (search, artist, album pages).
library;

/// Every map stored under [key] anywhere in [node], in document order.
List<Map> collectRenderers(Object? node, String key) {
  final out = <Map>[];
  void walk(Object? n) {
    if (n is Map) {
      for (final e in n.entries) {
        if (e.key == key && e.value is Map) {
          out.add(e.value as Map);
        } else {
          walk(e.value);
        }
      }
    } else if (n is List) {
      n.forEach(walk);
    }
  }

  walk(node);
  return out;
}

/// `{"runs": [{"text": …}]}` or `{"simpleText": …}` as plain text.
String runsText(Object? node) {
  if (node is! Map) return '';
  final simple = node['simpleText'];
  if (simple is String) return simple;
  final runs = node['runs'];
  if (runs is! List) return '';
  return [
    for (final r in runs)
      if (r is Map && r['text'] is String) r['text'] as String,
  ].join();
}

/// The `browseEndpoint` of a run or of an item holding a `navigationEndpoint`.
Map? _browseEndpoint(Object? run) {
  if (run is! Map) return null;
  final endpoint = run['navigationEndpoint'];
  if (endpoint is! Map) return null;
  final browse = endpoint['browseEndpoint'];
  return browse is Map ? browse : null;
}

/// `MUSIC_PAGE_TYPE_…` of the page a run links to, null when it links nowhere.
String? pageTypeOf(Object? run) {
  final browse = _browseEndpoint(run);
  final configs = browse?['browseEndpointContextSupportedConfigs'];
  if (configs is! Map) return null;
  final music = configs['browseEndpointContextMusicConfig'];
  return music is Map ? music['pageType'] as String? : null;
}

/// `browseId` of the page a run links to, null when it links nowhere.
String? browseIdOf(Object? run) {
  final id = _browseEndpoint(run)?['browseId'];
  return id is String && id.isNotEmpty ? id : null;
}

final _clock = RegExp(r'^(?:(\d+):)?(\d{1,2}):(\d{2})$');

/// `3:45`, `1:02:03` → a [Duration]; anything else → null.
Duration? parseClock(String text) {
  final m = _clock.firstMatch(text.trim());
  if (m == null) return null;
  return Duration(
    hours: int.parse(m.group(1) ?? '0'),
    minutes: int.parse(m.group(2)!),
    seconds: int.parse(m.group(3)!),
  );
}

/// The picture of a list item or card (`thumbnail` renderer), the smallest one
/// at least [minWidth] px wide, else the last (widest) one.
String? pickThumbnail(Object? node, {int minWidth = 120}) {
  final thumbs = collectRenderers(node, 'thumbnail');
  final list = thumbs.isEmpty ? null : thumbs.first['thumbnails'];
  if (list is! List) return null;
  String? best;
  for (final t in list) {
    if (t is! Map || t['url'] is! String) continue;
    best = t['url'] as String;
    final w = t['width'];
    if (w is num && w >= minWidth) break;
  }
  return best;
}

/// Words that only join credited artists («A & B», «A, B and C»).
const artistJoiners = {',', '&', 'and', 'e', 'y', 'et', 'und', 'x'};

/// The runs of a text node split on the « • » separators, one list per group;
/// empty groups are dropped.
List<List<Map>> bulletGroups(Object? textNode) {
  final runs = textNode is Map ? textNode['runs'] : null;
  final groups = <List<Map>>[[]];
  for (final r in runs is List ? runs : const []) {
    if (r is! Map || r['text'] is! String) continue;
    if ((r['text'] as String).trim() == '•') {
      groups.add([]);
    } else {
      groups.last.add(r);
    }
  }
  return [
    for (final g in groups)
      if (g.isNotEmpty) g,
  ];
}

/// A group of runs as plain text.
String groupText(List<Map> group) =>
    group.map((r) => r['text'] as String).join().trim();
