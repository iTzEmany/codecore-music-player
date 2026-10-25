import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_log.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/ytm_catalog_providers.dart';
import '../../services/online/artist_link_resolver.dart';
import '../../services/online/innertube_client.dart';
import '../../services/online/youtube_service.dart';
import '../../services/online/ytm_artist.dart';
import '../screens/library/artist_screen.dart';
import '../screens/online/artist_page_screen.dart';
import '../screens/online/artist_picker_sheet.dart';
import '../screens/youtube/online_results.dart' show ytErrorText;
import '../shell/shell_nav.dart';
import 'cc_sheet.dart';
import 'show_msg.dart';

/// Opens the page of a credited artist: library, then YouTube Music (a sheet
/// when several fit). Only ever started by the user's tap.
Future<void> openArtistLink(
  BuildContext context,
  WidgetRef ref,
  ArtistName a,
) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final resolver = ref.read(artistLinkResolverProvider);
  // The snackbar only appears if the library has no answer (the network is used).
  var searching = false;
  final ArtistLink link;
  try {
    link = await ArtistLinkResolver(
      library: resolver.library,
      search: (name) {
        searching = true;
        showMsg(context, l.ytmSearchingArtist);
        return resolver.search(name);
      },
    ).resolve(a.name, ytmId: a.ytmId);
  } on Object catch (e) {
    AppLog.w('artist link failed ($e)');
    if (!context.mounted) return;
    showMsg(
      context,
      e is YtException
          ? ytErrorText(context, e.kind)
          : e is InnerTubeChanged
          ? l.ytmPageUnreadable
          : l.loadFailed,
    );
    return;
  }
  if (searching) messenger.clearSnackBars();
  if (!context.mounted) return;
  switch (link) {
    case LibraryArtist(:final artist):
      ShellNav.openInLibrary(context, ref, ArtistDetailScreen(artist: artist));
    case OnlineArtist(:final artist):
      ShellNav.openInLibrary(context, ref, ArtistPageScreen(artist: artist));
    case ChooseArtists(:final artists):
      final YtmArtistRef? picked = await showCcSheet<YtmArtistRef>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => ArtistPickerSheet(artists: artists),
      );
      if (picked != null && context.mounted) {
        ShellNav.openInLibrary(context, ref, ArtistPageScreen(artist: picked));
      }
    case NoArtistLink():
      showMsg(context, l.ytmArtistNone);
  }
}
