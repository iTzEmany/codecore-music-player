import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/online/ytm_artist.dart' show YtmArtistRef;
import 'releases_providers.dart';

/// Followed artists and the releases they bring.
class FollowOps {
  FollowOps(this._ref);

  final Ref _ref;

  /// Follows [artist] and runs its first check at once (it stores everything
  /// as already seen, so the next round only tells what is really new).
  Future<void> follow(YtmArtistRef artist) async {
    await _ref.read(followRepositoryProvider).follow(artist);
    unawaited(_ref.read(releaseCheckControllerProvider).checkArtist(artist.id));
  }

  Future<void> unfollow(String id) => _ref.read(followRepositoryProvider).unfollow(id);
  Future<void> setMuted(String id, bool muted) => _ref.read(followRepositoryProvider).setMuted(id, muted);
  Future<void> retry(String id) => _ref.read(followRepositoryProvider).retry(id);

  /// The user picked [chosen] for a pending lookup: remember it and follow.
  Future<void> followPicked(String lookupKey, String lookupName, YtmArtistRef chosen) async {
    await _ref.read(followRepositoryProvider).saveLookup(lookupKey, lookupName, artist: chosen);
    await follow(chosen);
    _ref.invalidate(pendingArtistsProvider);
  }

  /// Opening a release clears its «new» dot.
  Future<void> markReleaseOpened(String browseId) => _ref.read(releaseRepositoryProvider).markOpened(browseId);
}

final followOpsProvider = Provider<FollowOps>(FollowOps.new);
