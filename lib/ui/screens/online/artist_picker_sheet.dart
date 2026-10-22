import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/ytm_catalog_providers.dart';
import '../../../services/online/innertube_client.dart';
import '../../../services/online/youtube_service.dart';
import '../../../services/online/ytm_artist.dart';
import '../../../services/online/ytm_artist_resolver.dart';
import '../../theme/tokens.dart';
import '../../widgets/net_thumbnail.dart';
import '../youtube/online_results.dart' show ytErrorText;
import 'artist_page_screen.dart';
import 'artist_page_sections.dart' show thumbAt;

/// «Su YouTube Music» from the library: looks the artist [name] up among
/// YouTube Music's artists and calls [open] with the page of the right one. A
/// single exact name opens by itself; otherwise the first three are offered.
/// Only ever started by the user's tap.
Future<void> openYtmArtist(
  BuildContext context,
  WidgetRef ref,
  String name, {
  required void Function(Widget page) open,
}) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(text)));
  say(l.ytmSearchingArtist);
  final List<YtmArtistRef> found;
  try {
    found = await ref
        .read(ytmCatalogProvider)
        .searchArtists(name, ref.read(ytmLanguageProvider));
  } on Object catch (e) {
    AppLog.w('artist lookup failed ($e)');
    if (!context.mounted) return;
    say(e is YtException
        ? ytErrorText(context, e.kind)
        : e is InnerTubeChanged
            ? l.ytmPageUnreadable
            : l.loadFailed);
    return;
  }
  messenger.clearSnackBars();
  if (!context.mounted) return;
  switch (pickYtmArtist(name, found)) {
    case ExactArtist(:final artist):
      open(ArtistPageScreen(artist: artist));
    case ChooseArtist(:final artists):
      final chosen = await showModalBottomSheet<YtmArtistRef>(
        context: context,
        showDragHandle: true,
        builder: (_) => ArtistPickerSheet(artists: artists),
      );
      if (chosen != null) open(ArtistPageScreen(artist: chosen));
    case NoArtist():
      say(l.ytmArtistNone);
  }
}

/// The few artists to choose from: photo, name and monthly audience.
class ArtistPickerSheet extends StatelessWidget {
  const ArtistPickerSheet({super.key, required this.artists});

  final List<YtmArtistRef> artists;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(CcDims.margin, 0, CcDims.margin, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l.ytmPickArtist, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          for (final a in artists)
            ListTile(
              key: ValueKey('pick-${a.id}'),
              leading: NetThumbnail(
                url: thumbAt(context, a.thumbnailUrl, 48),
                width: 48,
                height: 48,
                icon: Icons.person_rounded,
                circle: true,
              ),
              title: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: a.audience == null
                  ? null
                  : Text(a.audience!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cc.textMuted)),
              onTap: () => Navigator.pop(context, a),
            ),
        ],
      ),
    );
  }
}
