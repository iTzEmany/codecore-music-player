import '../../../providers/follow_ops.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart' show ArtistRelease;
import '../../../data/repositories/release_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/online/ytm_artist.dart';
import '../../../services/releases/release_diff.dart';
import '../../shell/shell_nav.dart';
import '../online/online_album_screen.dart';

/// «Album, 2026» / «Singolo, 2026» (just the word when the year is unknown).
String releaseKindLabel(AppLocalizations l, ArtistRelease r) {
  final single = ReleaseKind.values[r.kind] == ReleaseKind.single;
  final year = r.year;
  if (year == null) return single ? l.releaseSinglePlain : l.releaseAlbumPlain;
  return single ? l.releaseSingleYear('$year') : l.releaseAlbumYear('$year');
}

/// Opens the album page of [r] and marks it opened (the dot goes away).
void openRelease(BuildContext context, WidgetRef ref, RecentRelease r) {
  final rel = r.release;
  ref.read(followOpsProvider).markReleaseOpened(rel.browseId);
  ShellNav.open<void>(
    context,
    OnlineAlbumScreen(
      browseId: rel.browseId,
      release: YtmRelease(
        browseId: rel.browseId,
        title: rel.title,
        subtitle: '${rel.year ?? ''}',
        thumbnailUrl: rel.thumbUrl,
      ),
    ),
  );
}
