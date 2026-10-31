import 'package:drift/drift.dart' show Value;

import '../../data/db/app_database.dart';
import 'enrich_parts.dart';

/// The only place that writes `tracks.enrich_status`.
class EnrichWriter {
  EnrichWriter(this._db);

  final AppDatabase _db;

  Future<void> writeStatus(int trackId, EnrichStatus status) =>
      (_db.update(_db.tracks)..where((t) => t.id.equals(trackId))).write(
        TracksCompanion(enrichStatus: Value(status.code)),
      );
}
