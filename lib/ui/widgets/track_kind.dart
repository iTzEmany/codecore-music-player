import '../../data/db/app_database.dart';
import '../../services/audio/online_entries.dart' show isOnlineId;

/// Where a track comes from. Radio stations share the streamed ids: telling
/// them apart needs the queue's entries (see `radioOfTrack`), not the id.
enum TrackKind { local, episode, online }

extension TrackKindX on Track {
  /// Named `trackKind`: `Track.kind` is already the 0/1 library-or-episode column.
  TrackKind get trackKind => isOnlineId(id)
      ? TrackKind.online
      : kind == 1
      ? TrackKind.episode
      : TrackKind.local;
}
