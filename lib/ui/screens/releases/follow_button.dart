import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/releases_providers.dart';
import '../../../services/online/ytm_artist.dart';
import '../../widgets/confirm.dart';
import '../online/artist_picker_sheet.dart' show lookupYtmArtist;

/// Follows [artist] and runs its first check at once (it stores everything as
/// already seen, so the next round only tells what is really new).
Future<void> followArtist(WidgetRef ref, YtmArtistRef artist) async {
  await ref.read(followRepositoryProvider).follow(artist);
  unawaited(ref.read(releaseCheckControllerProvider).checkArtist(artist.id));
}

/// «Segui su YouTube Music» from the library: looks the artist up by name and
/// follows the one found (or the one picked among a few).
Future<void> followFromLibrary(
  BuildContext context,
  WidgetRef ref,
  String name,
) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final artist = await lookupYtmArtist(context, ref, name);
  if (artist == null) return;
  await followArtist(ref, artist);
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(l.followedNow(artist.name))));
}

/// «Segui» / «Segui già» on the page of an artist of YouTube Music; stopping
/// asks first.
class FollowButton extends ConsumerWidget {
  const FollowButton({super.key, required this.artist});

  final YtmArtistRef artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final followed = ref.watch(isFollowedProvider(artist.id)).value ?? false;
    if (!followed) {
      return FilledButton.icon(
        key: const ValueKey('follow-button'),
        onPressed: () => followArtist(ref, artist),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.followAction),
      );
    }
    return OutlinedButton.icon(
      key: const ValueKey('following-button'),
      onPressed: () async {
        final ok = await showConfirm(
          context,
          title: l.followStopTitle(artist.name),
          body: l.followStopBody,
          confirmLabel: l.followStop,
          destructive: true,
        );
        if (ok) await ref.read(followRepositoryProvider).unfollow(artist.id);
      },
      icon: const Icon(Icons.check_rounded),
      label: Text(l.followingAction),
    );
  }
}
