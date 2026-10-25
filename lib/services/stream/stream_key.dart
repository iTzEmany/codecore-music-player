import '../../data/db/app_database.dart' show Track;
import '../online/youtube_service.dart';

const _prefix = 'stream:';

/// Library path of a streamed track's shadow row.
String streamPathOf(String key) => '$_prefix$key';

/// The cache key of a `stream:<key>` path, or null for any other path.
String? keyOfStreamPath(String path) =>
    path.startsWith(_prefix) ? path.substring(_prefix.length) : null;

/// File name of [key] inside the cache folder.
String streamFileName(String key) => key.replaceAll(':', '_');

/// The artist shown for [r]: its credited artists, else the channel.
String displayArtist(YtResult r) => r.artists.isEmpty ? r.channel : r.artists.join(', ');

/// The download request of a shadow row, rebuilt from its [key] and the row;
/// the inverse of [YtResult.indexKey].
/// shortcut: the row keeps no artist ids, thumbnail or page address (a SoundCloud row can't be re-downloaded), fix with the first SoundCloud stream.
YtResult streamResultOfRow(String key, Track row) {
  final sep = key.indexOf(':');
  final source = MediaSource.values.firstWhere((m) => m.name == key.substring(0, sep),
      orElse: () => MediaSource.youtube);
  final artist = row.artist;
  return YtResult(
    id: key.substring(sep + 1),
    title: row.title,
    channel: artist ?? '',
    artists: artist == null ? const [] : [artist],
    album: row.album,
    duration: row.durationMs > 0 ? Duration(milliseconds: row.durationMs) : null,
    source: source,
  );
}
