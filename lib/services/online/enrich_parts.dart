import '../../data/db/app_database.dart';

/// The parts [EnrichmentService.completeOne] can fill.
enum EnrichPart { meta, lyrics, synced, curio, credits }

/// What one part of [EnrichmentService.completeOne] came to. [failed]: a source
/// did not answer and no «searched, nothing» mark was written; [skipped]: off,
/// not due, or no source reachable (no call made).
enum PartOutcome { found, none, failed, skipped }

/// A «searched, nothing» answer is asked again after this long.
const retryNoneAfter = Duration(days: 30);

/// Whether [part] of [track] is empty and worth asking for at [now]: never
/// searched, or searched with an empty answer more than 30 days ago.
/// [hasCredits] says whether `track_credits` has rows for the track.
/// `synced` is due only with a plain text the user did not write and no synced one.
/// [force] ignores a recent «searched, nothing» mark (the part must still be
/// empty, except `curio`, which a refresh redoes over a full column).
bool isDue(
  EnrichPart part,
  Track track,
  TrackEnrichData? enrich,
  DateTime now, {
  bool hasCredits = false,
  bool force = false,
}) {
  final byUser = enrich?.lyricsByUser ?? false;
  final (empty, noneAt) = switch (part) {
    EnrichPart.meta => (
      track.album == null ||
          track.year == null ||
          track.genre == null ||
          track.trackNumber == null ||
          !track.hasCover,
      enrich?.metaNoneAt,
    ),
    EnrichPart.lyrics => (
      !byUser && track.lyricsPlain == null && track.lyricsSynced == null,
      enrich?.lyricsNoneAt,
    ),
    EnrichPart.synced => (
      !byUser && track.lyricsPlain != null && track.lyricsSynced == null,
      enrich?.syncedNoneAt,
    ),
    // A refresh replaces the curiosities, so force asks over a full column too.
    EnrichPart.curio => (force || track.curiosities == null, enrich?.curioNoneAt),
    EnrichPart.credits => (!hasCredits, enrich?.creditsNoneAt),
  };
  if (!empty) return false;
  return force ||
      noneAt == null ||
      now.difference(DateTime.fromMillisecondsSinceEpoch(noneAt)) >
          retryNoneAfter;
}
