import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../data/db/app_database.dart' show Track;
import '../services/online/http_client.dart';
import '../services/online/query_cleaner.dart';
import 'database_providers.dart';
import 'online_providers.dart';
import 'settings_providers.dart';

/// What the last search could not do, per part: `songLimited` / `artistLimited`
/// = Wikipedia refused (too many requests), so «nothing found» would be a lie.
class CuriosityOutcome {
  const CuriosityOutcome({
    this.songLimited = false,
    this.artistLimited = false,
    this.failed = false,
    this.nothing = false,
  });

  final bool songLimited, artistLimited, failed, nothing;

  bool get limited => songLimited || artistLimited;
}

/// The curiosity search of one track (by id): loading while it runs, then how it
/// went (null before the first search). The results are saved in the DB here.
class CuriosityNotifier extends AsyncNotifier<CuriosityOutcome?> {
  CuriosityNotifier(this.trackId);

  final int trackId;

  @override
  CuriosityOutcome? build() => null;

  Future<CuriosityOutcome> fetch(Track t) async {
    state = const AsyncLoading();
    final c = cleanSearchQuery(t.title, t.artist ?? '');
    final lang = ref.read(settingsProvider).language;
    var songLimited = false, artistLimited = false, failed = false;

    // Identity first (MusicBrainz → Wikidata → the exact pages), the names
    // after; each part reports on its own, so one failing does not lose the other.
    final found = await ref
        .read(curiosityFinderProvider)
        .find(c.title, c.artist, lang, isrc: t.isrc, durationMs: t.durationMs);
    final song = found.song, artist = found.artist;
    final songDone = found.songError == null;
    for (final (err, isSong) in [
      (found.songError, true),
      (found.artistError, false),
    ]) {
      if (err == null) continue;
      if (err is RateLimitedException) {
        AppLog.w('curiosity refused', err);
        isSong ? songLimited = true : artistLimited = true;
      } else {
        AppLog.w('curiosity lookup failed', err);
        failed = true;
      }
    }
    try {
      // A new search replaces what was saved before, also with nothing: an
      // older version could have saved the artist's page as the song's. A part
      // that could not be asked is left as it was.
      if (songDone) {
        await ref
            .read(trackRepositoryProvider)
            .setCuriosities(
              t.id,
              song == null ? null : '${song.text}\n${song.source}',
            );
      }
      if (artist != null) {
        await ref
            .read(artistInfoRepositoryProvider)
            .save(
              c.artist,
              body: artist.text,
              source: artist.source,
              lang: artist.lang,
            );
      }
    } on Object catch (e, st) {
      AppLog.w('could not save the curiosities', e, st);
      failed = true;
    }
    final out = CuriosityOutcome(
      songLimited: songLimited,
      artistLimited: artistLimited,
      failed: failed,
      nothing: song == null && artist == null,
    );
    state = AsyncData(out);
    return out;
  }
}

final curiosityProvider = AsyncNotifierProvider.autoDispose
    .family<CuriosityNotifier, CuriosityOutcome?, int>(CuriosityNotifier.new);
