import '../../core/import_row.dart';
import '../import/track_matcher.dart';
import 'deezer_models.dart';
import 'youtube_service.dart';

/// Max gap between the local and the Deezer length, in seconds.
const _maxDurationGap = 3;

/// Versions that are never the wanted recording unless the local title says so.
const _rejectedVersions = ['instrumental', 'karaoke', 'live'];

/// What Codecore knows about a local track.
class DeezerWant {
  const DeezerWant({
    required this.title,
    this.artist = '',
    this.album,
    this.durationMs,
    this.isrc,
  });

  final String title, artist;
  final String? album, isrc;
  final int? durationMs;
}

/// «artist title album»; the album only when known.
String deezerQuery(DeezerWant w) => [
  w.artist,
  w.title,
  if (w.album != null) w.album!,
].where((s) => s.trim().isNotEmpty).join(' ');

bool _durationOk(DeezerWant w, DeezerTrack t) =>
    w.durationMs == null ||
    w.durationMs! <= 0 ||
    (t.duration * 1000 - w.durationMs!).abs() <= _maxDurationGap * 1000;

/// A track found by ISRC is the right recording unless its length is off.
bool acceptIsrcHit(DeezerWant w, DeezerTrack t) => _durationOk(w, t);

/// The best text-search candidate, or null when none is sure enough.
DeezerTrack? pickDeezerTrack(DeezerWant w, List<DeezerTrack> candidates) {
  // Without an ISRC the length is the only hard check: no length, no match.
  if ((w.durationMs ?? 0) <= 0) return null;
  final row = ImportRow(
    index: 0,
    title: w.title,
    artists: [if (w.artist.isNotEmpty) w.artist],
    album: w.album,
    durationMs: w.durationMs,
  );
  final wantKey = matchTitleKey(w.title);
  DeezerTrack? best;
  var bestScore = 0.0;
  for (final t in candidates) {
    final gotKey = matchTitleKey(t.title);
    final rejected = otherVersions
        .where(_rejectedVersions.contains)
        .any((v) => hasPhrase(gotKey, v) && !hasPhrase(wantKey, v));
    if (rejected || !_durationOk(w, t)) continue;
    final score = scoreCandidate(
      row,
      YtResult(
        id: '${t.id}',
        title: t.title,
        channel: t.artist,
        duration: Duration(seconds: t.duration),
        artists: [t.artist],
        album: t.album?.title,
      ),
    );
    if (score >= sureThreshold && score > bestScore) {
      best = t;
      bestScore = score;
    }
  }
  return best;
}

/// Which Deezer fields may be written. ISRC is always usable; the artist only
/// when the local one is empty (the caller checks that).
class DeezerEdition {
  const DeezerEdition({required this.albumUsable});

  /// Album name, cover, year, track and disc numbers.
  final bool albumUsable;
}

/// A compilation or a box set is not the record the track belongs to.
DeezerEdition checkEdition(String? localAlbum, DeezerAlbum album) {
  final local = localAlbum == null ? '' : matchTitleKey(localAlbum);
  return DeezerEdition(
    albumUsable:
        album.recordType != 'compile' &&
        album.nbTracks <= 40 &&
        (local.isEmpty || local == matchTitleKey(album.title)),
  );
}
