import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../core/constants.dart';
import '../../../data/db/app_database.dart' show Track;
import '../../../data/repositories/library_queries.dart' show ArtistSummary;
import '../../../l10n/l10n_ext.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/ytm_catalog_providers.dart';
import '../../../services/online/library_overlap.dart';
import '../../../services/online/youtube_service.dart';
import '../../../services/online/ytm_artist.dart';
import '../../shell/shell_nav.dart';
import '../../widgets/section_header.dart';
import '../../widgets/track_row.dart';
import '../library/artist_screen.dart';
import '../releases/follow_button.dart';
import '../youtube/online_results.dart';
import 'artist_page_sections.dart';
import 'artist_songs_screen.dart';
import 'catalog_error_view.dart';
import 'discography_screen.dart';
import 'online_album_screen.dart';
import 'online_page_frame.dart';
import 'online_song_row.dart';

/// The page of an artist on YouTube Music: the songs of the library first,
/// then top songs, releases, similar artists and the biography. [artist] is
/// the reference the page was opened from (it has the square photo).
class ArtistPageScreen extends ConsumerWidget {
  const ArtistPageScreen({super.key, required this.artist});

  final YtmArtistRef artist;

  String get _listKey => 'ytm-artist:${artist.id}';

  Future<void> _refresh(WidgetRef ref) async {
    try {
      await ref
          .read(ytmCatalogProvider)
          .artist(artist.id, ref.read(ytmLanguageProvider), refresh: true);
    } on Object catch (e) {
      AppLog.w('artist page: refresh failed ($e)');
    }
    ref.invalidate(artistPageProvider(artist.id));
  }

  /// The normal search for the artist's name, when the page cannot be read.
  void _searchSongs(BuildContext context) => ShellNav.open<void>(
        context,
        Scaffold(
          appBar: AppBar(title: Text(artist.name)),
          body: OnlineResults(query: artist.name, submitted: 1),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final page = ref.watch(artistPageProvider(artist.id));
    final local = localArtistFor(artist.name, ref.watch(artistsProvider).value ?? const []);
    final localTracks = local == null
        ? const <Track>[]
        : ref.watch(artistTracksProvider(local.key)).value ?? const <Track>[];
    final data = page.value;
    final songs = <YtResult>[];
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: ArtistHeader(
          artist: artist,
          audience: data?.value.ref.audience,
          action: kEnableYoutube ? FollowButton(artist: artist) : null,
        ),
      ),
    ];
    if (data != null) {
      if (data.stale) {
        slivers.add(SliverToBoxAdapter(child: OfflineNotice(fetchedAt: data.fetchedAt)));
      }
      if (local != null && localTracks.isNotEmpty) {
        slivers.addAll(_library(context, ref, local, localTracks));
      }
      final overlap = LibraryOverlap(localTracks);
      for (final shelf in data.value.shelves) {
        switch (shelf) {
          case YtmSongShelf():
            if (shelf.songs.isEmpty) break;
            final start = songs.length;
            songs.addAll(shelf.songs);
            slivers.addAll(_songs(context, shelf, start, overlap));
          case YtmReleaseShelf():
            if (shelf.releases.isEmpty) break;
            slivers.add(SliverToBoxAdapter(child: _releases(context, shelf)));
          case YtmArtistShelf():
            if (shelf.artists.isEmpty) break;
            slivers.add(SliverToBoxAdapter(
              child: ArtistList(
                shelf: shelf,
                onOpen: (a) =>
                    ShellNav.open<void>(context, ArtistPageScreen(artist: a)),
              ),
            ));
        }
      }
      final about = data.value.description?.trim() ?? '';
      if (about.isNotEmpty) slivers.add(SliverToBoxAdapter(child: AboutSection(text: about)));
    } else if (page.hasError) {
      slivers.add(SliverToBoxAdapter(
        child: CatalogErrorView(
          error: page.error!,
          onRetry: () => ref.invalidate(artistPageProvider(artist.id)),
          notFoundText: l.ytmArtistNotFound,
          unreadableText: l.ytmArtistUnreadable,
          onSearch: () => _searchSongs(context),
          searchLabel: l.ytmSearchSongsOf(artist.name),
        ),
      ));
    } else {
      slivers.add(const SliverToBoxAdapter(child: PageSkeleton()));
    }
    return OnlinePageFrame(
      title: artist.name,
      selectionKey: _listKey,
      pickable: songs,
      onRefresh: () => _refresh(ref),
      slivers: slivers,
    );
  }

  /// «Nella tua libreria»: up to five of the artist's songs you already have.
  List<Widget> _library(
      BuildContext context, WidgetRef ref, ArtistSummary local, List<Track> tracks) {
    final l = context.l10n;
    final shown = tracks.take(5).toList();
    final ctrl = ref.read(playerControllerProvider);
    final ctx = PlayContext(PlayContextKind.artist, local.name);
    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          l.ytmInYourLibrary,
          actionLabel: l.showAll,
          onAction: () => ShellNav.open<void>(context, ArtistDetailScreen(artist: local)),
        ),
      ),
      SliverList.builder(
        itemCount: shown.length,
        itemBuilder: (_, i) => SizedBox(
          height: 64,
          child: LiveTrackRow(
            track: shown[i],
            onTap: () => ctrl.playFromList(tracks, i, context: ctx),
          ),
        ),
      ),
    ];
  }

  List<Widget> _songs(
      BuildContext context, YtmSongShelf shelf, int start, LibraryOverlap overlap) {
    final l = context.l10n;
    final link = shelf.allSongs;
    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          shelf.title,
          actionLabel: link == null ? null : l.showAll,
          onAction: link == null
              ? null
              : () => ShellNav.open<void>(
                  context, ArtistSongsScreen(artist: artist, title: shelf.title, link: link)),
        ),
      ),
      SliverList.builder(
        itemCount: shelf.songs.length,
        itemBuilder: (_, i) => OnlineSongTile(
          result: shelf.songs[i],
          index: start + i,
          selectionKey: _listKey,
          ownedLocally: overlap.owns(shelf.songs[i]),
        ),
      ),
    ];
  }

  Widget _releases(BuildContext context, YtmReleaseShelf shelf) {
    final more = shelf.more;
    return ReleaseList(
      shelf: shelf,
      onOpen: (r) => ShellNav.open<void>(
          context, OnlineAlbumScreen(browseId: r.browseId, release: r)),
      onMore: more == null
          ? null
          : () => ShellNav.open<void>(
              context, DiscographyScreen(artist: artist, title: shelf.title, link: more)),
    );
  }
}
