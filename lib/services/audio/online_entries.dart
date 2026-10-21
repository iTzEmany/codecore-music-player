import '../../data/db/app_database.dart';
import '../online/youtube_service.dart';

/// Online entries in the queue have negative ids; library tracks are > 0.
bool isOnlineId(int id) => id < 0;

/// One streamed (not owned) track: what to play and why it is there.
class OnlineEntry {
  const OnlineEntry({
    required this.id,
    required this.result,
    required this.addedAt,
    this.seedTitle,
  });

  final int id;
  final YtResult result;

  /// The library track this one is «similar to», if any.
  final String? seedTitle;
  final DateTime addedAt;
}

/// In-memory registry of the online entries of this session. Never written to
/// the database; ids are never reused, even after [forget].
class OnlineEntries {
  OnlineEntries({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<int, OnlineEntry> _entries = {};
  int _last = 0;

  int register(YtResult result, {String? seedTitle}) {
    final id = --_last;
    _entries[id] = OnlineEntry(
      id: id,
      result: result,
      seedTitle: seedTitle,
      addedAt: _now(),
    );
    return id;
  }

  OnlineEntry? operator [](int id) => _entries[id];

  /// Same as `[]`, readable after a `?.` or `?` in an expression.
  OnlineEntry? entryOf(int id) => _entries[id];

  void forget(int id) => _entries.remove(id);

  /// A synthetic track for screens, notification and MPRIS. Never stored.
  Track? trackOf(int id) {
    final e = _entries[id];
    if (e == null) return null;
    final r = e.result;
    return Track(
      id: id,
      path: 'online:${r.source.name}:${r.id}',
      title: r.title,
      artist: r.artists.isEmpty ? r.channel : r.artists.join(', '),
      album: r.album,
      albumKey: '',
      durationMs: r.duration?.inMilliseconds ?? 0,
      format: 'online',
      sizeBytes: 0,
      mtimeMs: 0,
      hasCover: false,
      coverKey: null,
      isFavorite: false,
      enrichStatus: 0,
      userEdited: false,
      missing: false,
      ignored: false,
      kind: 0,
      addedAt: e.addedAt.millisecondsSinceEpoch,
      playCount: 0,
    );
  }
}
