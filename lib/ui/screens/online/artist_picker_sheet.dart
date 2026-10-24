import '../../widgets/cc_sheet.dart';
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

/// Looks the artist [name] up among YouTube Music's artists: a single exact
/// name is the answer, otherwise the first few are offered in a sheet. Null
/// (after saying why) when nobody was found or chosen. Only ever started by
/// the user's tap.
Future<YtmArtistRef?> lookupYtmArtist(
  BuildContext context,
  WidgetRef ref,
  String name,
) async {
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
    if (!context.mounted) return null;
    say(
      e is YtException
          ? ytErrorText(context, e.kind)
          : e is InnerTubeChanged
          ? l.ytmPageUnreadable
          : l.loadFailed,
    );
    return null;
  }
  messenger.clearSnackBars();
  if (!context.mounted) return null;
  switch (pickYtmArtist(name, found)) {
    case ExactArtist(:final artist):
      return artist;
    case ChooseArtist(:final artists):
      return showCcSheet<YtmArtistRef>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => ArtistPickerSheet(artists: artists),
      );
    case NoArtist():
      say(l.ytmArtistNone);
      return null;
  }
}

/// «Su YouTube Music» from the library: opens the page of the artist found.
Future<void> openYtmArtist(
  BuildContext context,
  WidgetRef ref,
  String name, {
  required void Function(Widget page) open,
}) async {
  final artist = await lookupYtmArtist(context, ref, name);
  if (artist != null) open(ArtistPageScreen(artist: artist));
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CcDims.margin,
                0,
                CcDims.margin,
                8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.ytmPickArtist,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                // Many entries already exceed the max height, so lazy changes nothing visible.
                shrinkWrap: artists.length <= 20,
                itemCount: artists.length,
                itemBuilder: (context, i) {
                  final a = artists[i];
                  return ListTile(
                      key: ValueKey('pick-${a.id}'),
                      leading: NetThumbnail(
                        url: thumbAt(context, a.thumbnailUrl, 48),
                        width: 48,
                        height: 48,
                        icon: Icons.person_rounded,
                        circle: true,
                      ),
                      title: Text(
                        a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: a.audience == null
                          ? null
                          : Text(
                              a.audience!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: cc.textMuted),
                            ),
                      onTap: () => Navigator.pop(context, a),
                    );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
