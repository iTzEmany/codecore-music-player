import '../../data/db/app_database.dart';
import '../../data/repositories/import_repository.dart';

final _blockSuffix = RegExp(r' \((\d+)/(\d+)\)$');

/// «Liked Songs (3/23)» → the import's name, the block and how many there
/// are; null for an import made in one piece.
({String name, int part, int parts})? blockOf(String sourceName) {
  final m = _blockSuffix.firstMatch(sourceName);
  if (m == null) return null;
  return (
    name: sourceName.substring(0, m.start),
    part: int.parse(m.group(1)!),
    parts: int.parse(m.group(2)!),
  );
}

/// The name the user gave the import, without the block number.
String importLabel(String sourceName) => blockOf(sourceName)?.name ?? sourceName;

/// The imports as the user sees them: the blocks of one file imported «a
/// blocchi» together and in order, as one import; everything else on its own.
/// A chain is one run of blocks created together (ids in order, parts 1, 2,
/// 3…): the same file imported again into the same playlist is another chain.
List<List<PlaylistImport>> groupImportChains(Iterable<PlaylistImport> imports) {
  final sorted = [...imports]..sort((a, b) => a.id.compareTo(b.id));
  final groups = <List<PlaylistImport>>[];
  final open = <String, List<PlaylistImport>>{};
  for (final i in sorted) {
    final b = blockOf(i.sourceName);
    if (b == null) {
      groups.add([i]);
      continue;
    }
    final key = '${i.playlistId}:${b.parts}:${b.name}';
    final chain = open[key];
    if (chain != null && b.part > 1 && blockOf(chain.last.sourceName)!.part == b.part - 1) {
      chain.add(i);
    } else {
      groups.add(open[key] = [i]);
    }
  }
  return groups;
}

/// The block to start once [finished] is done: the next one of the same chain
/// that is waiting. Read from the imports themselves, so it also works after
/// the app was closed and opened again.
PlaylistImport? nextBlockAfter(PlaylistImport finished, Iterable<PlaylistImport> samePlaylist) {
  final b = blockOf(finished.sourceName);
  if (b == null) return null;
  for (final chain in groupImportChains(samePlaylist)) {
    final at = chain.indexWhere((i) => i.id == finished.id);
    if (at < 0) continue;
    for (final i in chain.skip(at + 1)) {
      if (i.state == ImportStatus.paused) return i;
    }
    return null;
  }
  return null;
}
