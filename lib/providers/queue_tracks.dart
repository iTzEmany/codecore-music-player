import '../data/db/app_database.dart';
import '../data/repositories/track_repository.dart';
import '../services/audio/online_entries.dart';

/// The on-screen queue: one track per position that can be shown. Library ids
/// come from the database, online ids (negative) from the registry as
/// synthetic tracks. Ids that resolve to nothing (a deleted row, a forgotten
/// online entry) are skipped.
Future<List<Track>> queueTracks(
  List<int> ids,
  TrackRepository repo,
  OnlineEntries? online,
) async {
  final library = await repo.getByIdsLight([
    for (final id in ids)
      if (!isOnlineId(id)) id,
  ]);
  final byId = {for (final t in library) t.id: t};
  return [
    for (final id in ids)
      if (isOnlineId(id))
        ?online?.trackOf(id)
      else
        ?byId[id],
  ];
}
