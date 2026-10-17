import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../data/db/app_database.dart';
import '../data/repositories/duplicate_repository.dart';
import '../services/library/duplicate_cleanup.dart';
import '../services/library/duplicate_finder.dart';
import '../services/library/file_hasher.dart';
import 'database_providers.dart';
import 'settings_providers.dart';

final duplicateRepositoryProvider = Provider<DuplicateRepository>(
  (ref) => DuplicateRepository(ref.watch(databaseProvider)),
);

/// Reads a file's SHA-256; tests replace it.
final duplicateHasherProvider = Provider<FileHasher>((ref) => sha256OfFile);

/// Deletes one file; null = the real `File.delete`. Tests replace it.
final duplicateDeleterProvider = Provider<FileDeleter?>((ref) => null);

typedef DuplicateGrouper =
    Future<List<DuplicateGroup>> Function(
      List<DupEntry> lib,
      Map<int, String> hashes,
    );

/// Grouping runs in another isolate: at 50 000 tracks it is not instant.
final duplicateGrouperProvider = Provider<DuplicateGrouper>(
  (ref) =>
      (lib, hashes) => Isolate.run(() => findDuplicates(lib, hashes: hashes)),
);

enum DuplicatePhase { idle, reading, hashing, grouping, done, failed }

/// A merge done in this session: its duplicate files can still be deleted.
class MergedDuplicates {
  const MergedDuplicates(this.keeper, this.dropped);

  final DupEntry keeper;
  final List<DupEntry> dropped;

  int get bytes => dropped.fold(0, (n, e) => n + e.sizeBytes);
}

class DuplicateSearchState {
  const DuplicateSearchState({
    this.phase = DuplicatePhase.idle,
    this.done = 0,
    this.total = 0,
    this.groups = const [],
    this.merged = const [],
  });

  final DuplicatePhase phase;
  final int done, total;
  final List<DuplicateGroup> groups;
  final List<MergedDuplicates> merged;

  bool get running =>
      phase == DuplicatePhase.reading ||
      phase == DuplicatePhase.hashing ||
      phase == DuplicatePhase.grouping;

  DuplicateSearchState copyWith({
    DuplicatePhase? phase,
    int? done,
    int? total,
    List<DuplicateGroup>? groups,
    List<MergedDuplicates>? merged,
  }) => DuplicateSearchState(
    phase: phase ?? this.phase,
    done: done ?? this.done,
    total: total ?? this.total,
    groups: groups ?? this.groups,
    merged: merged ?? this.merged,
  );
}

class DuplicateSearchNotifier extends Notifier<DuplicateSearchState> {
  bool _cancelled = false;

  @override
  DuplicateSearchState build() => const DuplicateSearchState();

  /// Finds the duplicates: reads the light entries, hashes the files that
  /// share a size with another (cached hashes are reused), then groups.
  Future<void> start() async {
    if (state.running) return;
    _cancelled = false;
    state = DuplicateSearchState(
      phase: DuplicatePhase.reading,
      merged: state.merged,
    );
    try {
      final repo = ref.read(duplicateRepositoryProvider);
      final entries = await repo.entries();
      state = state.copyWith(
        phase: DuplicatePhase.hashing,
        total: hashCandidates(entries).length,
      );
      final hashes = await hashDuplicateCandidates(
        entries,
        hasher: ref.read(duplicateHasherProvider),
        onProgress: (d, t) => state = state.copyWith(done: d, total: t),
        isCancelled: () => _cancelled,
      );
      // Even a partial pass is worth keeping: the next one skips those files.
      await repo.saveHashes(hashes);
      if (_cancelled) {
        state = DuplicateSearchState(merged: state.merged);
        return;
      }
      state = state.copyWith(phase: DuplicatePhase.grouping);
      final groups = await ref.read(duplicateGrouperProvider)(entries, hashes);
      final notDuplicates = ref.read(settingsStoreProvider).readNotDuplicates();
      state = state.copyWith(
        phase: DuplicatePhase.done,
        groups: [
          for (final g in groups)
            if (!notDuplicates.contains(g.key)) g,
        ],
      );
    } on Object catch (e, st) {
      AppLog.e('duplicate search failed', e, st);
      state = DuplicateSearchState(
        phase: DuplicatePhase.failed,
        merged: state.merged,
      );
    }
  }

  void cancel() => _cancelled = true;

  /// Merges [g] into [keepId]; the others are hidden and their data moves.
  Future<void> merge(DuplicateGroup g, int keepId) async {
    final keeper = g.members.firstWhere((m) => m.id == keepId);
    final dropped = [
      for (final m in g.members)
        if (m.id != keepId) m,
    ];
    await ref
        .read(duplicateRepositoryProvider)
        .merge(keepId, [for (final d in dropped) d.id]);
    state = state.copyWith(
      groups: [
        for (final x in state.groups)
          if (x.key != g.key) x,
      ],
      merged: [...state.merged, MergedDuplicates(keeper, dropped)],
    );
  }

  /// Merges every byte-for-byte group into its proposed track.
  Future<int> mergeAllExact() async {
    var n = 0;
    for (final g in [
      for (final x in state.groups)
        if (x.exact) x,
    ]) {
      await merge(g, g.proposed.id);
      n++;
    }
    return n;
  }

  /// «Not duplicates»: the group is not offered again (until its members change).
  Future<void> notDuplicates(DuplicateGroup g) async {
    final store = ref.read(settingsStoreProvider);
    await store.writeNotDuplicates({...store.readNotDuplicates(), g.key});
    state = state.copyWith(
      groups: [
        for (final x in state.groups)
          if (x.key != g.key) x,
      ],
    );
  }

  /// Deletes from disk the files left by the merges of this session, then
  /// forgets their (hidden) library rows. One file failing does not stop the
  /// others; the report says what happened to each.
  Future<DeleteReport> deleteMergedFiles({FileDeleter? deleter}) async {
    final deleted = <DupEntry>[];
    final failed = <DupEntry, String>{};
    final skipped = <DupEntry>[];
    final use = deleter ?? ref.read(duplicateDeleterProvider);
    for (final m in state.merged) {
      final r = use == null
          ? await deleteDuplicateFiles(m.keeper, m.dropped)
          : await deleteDuplicateFiles(m.keeper, m.dropped, deleter: use);
      deleted.addAll(r.deleted);
      failed.addAll(r.failed);
      skipped.addAll(r.skipped);
    }
    final tracks = ref.read(trackRepositoryProvider);
    for (final d in deleted) {
      await tracks.deleteTrack(d.id);
    }
    state = state.copyWith(merged: const []);
    return DeleteReport(deleted: deleted, failed: failed, skipped: skipped);
  }
}

final duplicateSearchProvider =
    NotifierProvider<DuplicateSearchNotifier, DuplicateSearchState>(
      DuplicateSearchNotifier.new,
    );

/// Tracks hidden by a merge, for «Brani nascosti».
final hiddenTracksProvider = StreamProvider.autoDispose<List<Track>>(
  (ref) => ref.watch(trackRepositoryProvider).watchIgnored(),
);
