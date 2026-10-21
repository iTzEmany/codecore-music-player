import '../../core/text_utils.dart' show sanitizeFileName;
import 'ytm_artist.dart';
import 'youtube_service.dart';

/// Roughly what a minute of M4A weighs.
const _bytesPerMinute = 1024 * 1024;

/// Length assumed for a song whose length is unknown.
const _unknownLength = Duration(minutes: 3);

/// What «Scarica album» is going to do, for the confirmation and the import.
class AlbumDownloadPlan {
  const AlbumDownloadPlan({
    required this.importName,
    required this.folder,
    required this.tracks,
    required this.owned,
    required this.duration,
    required this.estimatedBytes,
  });

  /// Name of the import: «Album — Artist».
  final String importName;

  /// Sub-folder of the download folder: «Artist - Album».
  final String folder;

  /// Every song in the album's order (the ones already in the library are
  /// linked by the import, not downloaded again).
  final List<YtResult> tracks;

  /// How many of [tracks] are already in the library.
  final int owned;

  /// Of the whole album.
  final Duration duration;

  /// Of the songs still to download.
  final int estimatedBytes;
}

AlbumDownloadPlan albumDownloadPlan(YtmAlbum album, bool Function(YtResult) isOwned) {
  final numbered = album.tracks.isNotEmpty && album.tracks.every((t) => t.number != null);
  final rows = [...album.tracks];
  if (numbered) rows.sort((a, b) => a.number!.compareTo(b.number!));
  final tracks = [for (final t in rows) t.result];
  var owned = 0;
  var total = Duration.zero;
  var toGet = Duration.zero;
  for (final r in tracks) {
    final length = r.duration ?? _unknownLength;
    total += r.duration ?? Duration.zero;
    if (isOwned(r)) {
      owned++;
    } else {
      toGet += length;
    }
  }
  final artist = album.artist?.name.trim() ?? '';
  return AlbumDownloadPlan(
    importName: artist.isEmpty ? album.title : '${album.title} — $artist',
    folder: sanitizeFileName(artist.isEmpty ? album.title : '$artist - ${album.title}'),
    tracks: tracks,
    owned: owned,
    duration: total,
    estimatedBytes: (toGet.inSeconds / 60 * _bytesPerMinute).round(),
  );
}
