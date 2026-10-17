import 'package:drift/drift.dart';

import '../../services/library/duplicate_finder.dart';
import '../db/app_database.dart';

/// Reads for the duplicate search; the merge itself is added next to it.
class DuplicateRepository {
  DuplicateRepository(this._db);

  final AppDatabase _db;

  /// Every visible track as the finder sees it. Plain SQL: the typed API
  /// costs ~15 µs per row, which is most of the time at 50 000 tracks.
  Future<List<DupEntry>> entries() async {
    final rows = await _db
        .customSelect(
          'SELECT id, path, title, artist, duration_ms, format, size_bytes, '
          'bitrate_kbps, sample_rate_hz, bit_depth, has_cover, user_edited, '
          'added_at, sha256 FROM tracks WHERE missing = 0 AND ignored = 0',
          readsFrom: {_db.tracks},
        )
        .get();
    return [
      for (final r in rows)
        DupEntry(
          id: r.data['id']! as int,
          path: r.data['path']! as String,
          title: (r.data['title'] as String?) ?? '',
          artist: r.data['artist'] as String?,
          durationMs: (r.data['duration_ms'] as int?) ?? 0,
          format: (r.data['format'] as String?) ?? '',
          sizeBytes: (r.data['size_bytes'] as int?) ?? 0,
          bitrateKbps: r.data['bitrate_kbps'] as int?,
          sampleRateHz: r.data['sample_rate_hz'] as int?,
          bitDepth: r.data['bit_depth'] as int?,
          hasCover: (r.data['has_cover'] as int? ?? 0) != 0,
          userEdited: (r.data['user_edited'] as int? ?? 0) != 0,
          addedAt: (r.data['added_at'] as int?) ?? 0,
          sha256: r.data['sha256'] as String?,
        ),
    ];
  }

  /// Remembers hashes so a later search does not read the files again. The
  /// scanner clears one when the file's size or time changes.
  Future<void> saveHashes(Map<int, String> hashes) async {
    if (hashes.isEmpty) return;
    await _db.transaction(() async {
      for (final e in hashes.entries) {
        await (_db.update(_db.tracks)..where((t) => t.id.equals(e.key)))
            .write(TracksCompanion(sha256: Value(e.value)));
      }
    });
  }
}
