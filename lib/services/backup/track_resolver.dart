import '../../core/import_row.dart';
import '../import/track_matcher.dart';
import '../online/query_cleaner.dart';
import 'user_data.dart';

/// Finds the local track a backup reference points to. A wrong match is worse
/// than none, so ties resolve to null.
class TrackResolver {
  TrackResolver(
    Iterable<LibraryEntryLite> library,
    Map<int, String> relPathById, {
    Map<int, String> sha256ById = const {},
    this.caseInsensitive = false,
  }) {
    for (final t in library) {
      final rel = relPathById[t.id];
      if (rel != null) (_byRelPath[_pathKey(rel)] ??= []).add(t.id);
      final sha = sha256ById[t.id];
      if (sha != null) (_bySha[sha] ??= []).add(t.id);
      (_byTitle['${matchTitleKey(t.title)}|${_artistKey(t.artist)}'] ??= [])
          .add(t);
    }
  }

  /// Windows paths ignore case; set when the backup or this device is Windows.
  final bool caseInsensitive;
  final Map<String, List<int>> _byRelPath = {};
  final Map<String, List<int>> _bySha = {};
  final Map<String, List<LibraryEntryLite>> _byTitle = {};

  static const durationToleranceMs = 2000;

  String _pathKey(String p) {
    final s = p.replaceAll(r'\', '/');
    return caseInsensitive ? s.toLowerCase() : s;
  }

  static String _artistKey(String? a) =>
      matchKey(extractPrimaryArtist(a ?? ''));

  int? resolve(TrackRef r) {
    final byPath = r.relPath == null ? null : _byRelPath[_pathKey(r.relPath!)];
    if (byPath != null && byPath.length == 1) return byPath.single;

    final byMeta = _byMetadata(r);
    if (byMeta != null) return byMeta;

    final sha = r.sha256 == null ? null : _bySha[r.sha256!];
    return sha != null && sha.length == 1 ? sha.single : null;
  }

  int? _byMetadata(TrackRef r) {
    final c = _byTitle['${matchTitleKey(r.title)}|${_artistKey(r.artist)}'];
    if (c == null) return null;
    final scored = <(int distance, int id)>[];
    for (final t in c) {
      final known = r.durationMs > 0 && t.durationMs > 0;
      final d = known ? (t.durationMs - r.durationMs).abs() : 0;
      if (d <= durationToleranceMs) scored.add((d, t.id));
    }
    if (scored.isEmpty) return null;
    scored.sort((a, b) => a.$1.compareTo(b.$1));
    if (scored.length > 1 && scored[0].$1 == scored[1].$1) return null;
    return scored.first.$2;
  }
}
