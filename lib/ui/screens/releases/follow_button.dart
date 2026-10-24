import '../../../providers/follow_ops.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/releases_providers.dart';
import '../../../services/online/ytm_artist.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm.dart';
import '../online/artist_picker_sheet.dart' show lookupYtmArtist;
import '../../widgets/show_msg.dart';

/// «Segui su YouTube Music» from the library: looks the artist up by name and
/// follows the one found (or the one picked among a few).
Future<void> followFromLibrary(
  BuildContext context,
  WidgetRef ref,
  String name,
) async {
  final l = context.l10n;
  final artist = await lookupYtmArtist(context, ref, name);
  if (artist == null) return;
  await ref.read(followOpsProvider).follow(artist);
  if (!context.mounted) return;
  showMsg(context, l.followedNow(artist.name));
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
      return OutlinedButton.icon(
        key: const ValueKey('follow-button'),
        onPressed: () => ref.read(followOpsProvider).follow(artist),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.followAction),
      );
    }
    return OutlinedButton.icon(
      key: const ValueKey('following-button'),
      style: OutlinedButton.styleFrom(foregroundColor: context.cc.accent),
      onPressed: () async {
        final ok = await showConfirm(
          context,
          title: l.followStopTitle(artist.name),
          body: l.followStopBody,
          confirmLabel: l.followStop,
          destructive: true,
        );
        if (ok) await ref.read(followOpsProvider).unfollow(artist.id);
      },
      icon: const Icon(Icons.check_rounded),
      label: Text(l.followingAction),
    );
  }
}
