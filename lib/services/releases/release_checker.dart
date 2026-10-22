import '../../core/app_log.dart';
import '../../data/db/app_database.dart' show FollowedArtist;
import '../../data/repositories/follow_repository.dart';
import '../../data/repositories/release_repository.dart';
import '../online/innertube_client.dart' show ArtistNotFound, InnerTubeChanged;
import '../online/youtube_service.dart' show YtErrorKind, YtException;
import '../online/ytm_artist.dart';
import 'release_diff.dart';

/// Reads the releases page of an artist (`YtmCatalog.releases`).
typedef ReleasesFetch = Future<YtmArtistPage> Function(String artistId);

/// Why a round stopped before the last artist.
enum CheckStop { rateLimited, offline, changed, cancelled }

/// A new release with the artist it belongs to.
class FreshRelease {
  const FreshRelease(this.artist, this.release);

  final FollowedArtist artist;
  final NewRelease release;
}

class CheckOutcome {
  const CheckOutcome({
    this.fresh = const [],
    this.checked = 0,
    this.failed = 0,
    this.stoppedBy,
    this.retryAt,
  });

  final List<FreshRelease> fresh;
  final int checked, failed;
  final CheckStop? stoppedBy;

  /// Set after a 429: the earliest time for another round.
  final DateTime? retryAt;
}

/// Lets the caller stop a round (network gone, option switched off).
class CheckCancel {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

/// One round of checks: the artists to check, one at a time, [gap] apart.
/// The first check of an artist stores everything as seen.
class ReleaseChecker {
  ReleaseChecker(
    this.fetch,
    this.follows,
    this.releases, {
    DateTime Function()? now,
    this.gap = const Duration(milliseconds: 1500),
    this.pause = const Duration(hours: 6),
    this.limit = 115,
    Future<void> Function(Duration)? wait,
  })  : _now = now ?? DateTime.now,
        _wait = wait ?? ((d) => Future<void>.delayed(d));

  final ReleasesFetch fetch;
  final FollowRepository follows;
  final ReleaseRepository releases;
  final Duration gap, pause;
  final int limit;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _wait;

  Future<CheckOutcome> run({CheckCancel? cancel}) async {
    final artists = await follows.toCheck(limit: limit);
    final fresh = <FreshRelease>[];
    var checked = 0, failed = 0;
    CheckOutcome stop(CheckStop why, {DateTime? retryAt}) => CheckOutcome(
        fresh: fresh, checked: checked, failed: failed, stoppedBy: why, retryAt: retryAt);

    for (var i = 0; i < artists.length; i++) {
      final artist = artists[i];
      if (i > 0) await _wait(gap);
      if (cancel?.isCancelled ?? false) return stop(CheckStop.cancelled);
      try {
        final page = await fetch(artist.ytmId);
        final first = artist.lastCheckedAt == null;
        final diff = diffReleases(
          known: first ? const {} : await releases.knownIds(artist.ytmId),
          knownGroups: first ? const {} : await releases.knownGroups(artist.ytmId),
          fetched: page.shelves.whereType<YtmReleaseShelf>().toList(),
          firstCheck: first,
          now: _now(),
        );
        await releases.store(artist.ytmId, diff);
        await follows.markChecked(artist.ytmId);
        checked++;
        fresh.addAll([for (final n in diff.fresh) FreshRelease(artist, n)]);
      } on ArtistNotFound {
        await follows.markChecked(artist.ytmId, error: kArtistNotFound);
        failed++;
      } on YtException catch (e) {
        switch (e.kind) {
          case YtErrorKind.rateLimited:
            AppLog.w('release check paused by YouTube (429)');
            return stop(CheckStop.rateLimited, retryAt: _now().add(pause));
          case YtErrorKind.network:
            return stop(CheckStop.offline);
          default:
            AppLog.w('release check of ${artist.name} failed: $e');
            await follows.markChecked(artist.ytmId, error: e.kind.name);
            failed++;
        }
      } on InnerTubeChanged catch (e) {
        AppLog.w('release check stopped, page not readable: $e');
        return stop(CheckStop.changed);
      }
    }
    return CheckOutcome(fresh: fresh, checked: checked, failed: failed);
  }
}
