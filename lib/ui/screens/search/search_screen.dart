import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/library_queries.dart';
import '../../../data/repositories/library_search.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/ui_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/artist_avatar.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/playlist_cover.dart';
import '../../widgets/section_header.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/track_row.dart';
import '../../widgets/track_row_selection.dart';
import '../library/album_detail_screen.dart';
import '../library/artist_screen.dart';
import '../playlists/playlist_detail_screen.dart';
import '../youtube/youtube_results.dart';
import 'genre_screen.dart';

enum _Mode { library, youtube }

/// Search: one pill, [Libreria] and [YouTube] chips. YouTube only runs when
/// the user submits.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _text = '';
  _Mode _mode = _Mode.library;
  int _ytSubmitted = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _text = v.trim());
    });
  }

  void _remember(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    ref
        .read(settingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            recentSearches: [
              t,
              ...s.recentSearches.where(
                (e) => e.toLowerCase() != t.toLowerCase(),
              ),
            ].take(10).toList(),
          ),
        );
  }

  void _submit(String v) {
    _debounce?.cancel();
    setState(() => _text = v.trim());
    if (_mode == _Mode.youtube) {
      setState(() => _ytSubmitted++);
    } else {
      _remember(v);
    }
  }

  void _useRecent(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    setState(() => _text = q);
  }

  void _toYoutube() {
    _remember(_text);
    setState(() {
      _mode = _Mode.youtube;
      _ytSubmitted++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context).textTheme;
    final Widget body;
    if (_mode == _Mode.youtube) {
      body = YoutubeResults(query: _text, submitted: _ytSubmitted);
    } else if (_text.isEmpty) {
      body = _EmptyQuery(onRecent: _useRecent);
    } else {
      body = _LibraryResults(text: _text, onYoutube: _toYoutube);
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CcDims.margin,
              12,
              CcDims.margin,
              8,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l.navSearch, style: theme.headlineSmall),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
            child: TextField(
              controller: _controller,
              focusNode: ref.watch(searchFocusProvider),
              onChanged: _onChanged,
              onSubmitted: _submit,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: _mode == _Mode.youtube ? l.ytHint : l.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l.cancel,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _text = '');
                        },
                      ),
              ),
            ),
          ),
          if (kEnableYoutube)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: CcDims.margin,
                  vertical: 8,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l.navLibrary),
                      selected: _mode == _Mode.library,
                      onSelected: (_) => setState(() => _mode = _Mode.library),
                    ),
                  ),
                  ChoiceChip(
                    label: Text(l.youtube),
                    selected: _mode == _Mode.youtube,
                    onSelected: (_) => setState(() => _mode = _Mode.youtube),
                  ),
                ],
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Recent searches and the genre tiles.
class _EmptyQuery extends ConsumerWidget {
  const _EmptyQuery({required this.onRecent});

  final void Function(String) onRecent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final recents = ref.watch(settingsProvider.select((s) => s.recentSearches));
    final genres = ref.watch(genresProvider).value ?? const <GenreSummary>[];
    return ListView(
      children: [
        if (recents.isNotEmpty) ...[
          SectionHeader(l.recentSearches),
          for (final q in recents)
            ListTile(
              leading: Icon(Icons.history_rounded, color: cc.textMuted),
              title: Text(q, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                tooltip: l.removeRecentSearch,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => ref
                    .read(settingsProvider.notifier)
                    .update(
                      (s) => s.copyWith(
                        recentSearches: [...s.recentSearches]..remove(q),
                      ),
                    ),
              ),
              onTap: () => onRecent(q),
            ),
        ],
        if (genres.isNotEmpty) ...[
          SectionHeader(l.genresTitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: [
                for (final g in genres)
                  _GenreTile(
                    genre: g,
                    onTap: () => ShellNav.open<void>(
                      context,
                      GenreScreen(genre: g.name),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _GenreTile extends StatelessWidget {
  const _GenreTile({required this.genre, required this.onTap});

  final GenreSummary genre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hue = artistHue(genre.name);
    final color = HSLColor.fromAHSL(1, hue, 0.5, 0.26).toColor();
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(CcDims.rCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              genre.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryResults extends ConsumerWidget {
  const _LibraryResults({required this.text, required this.onYoutube});

  final String text;
  final VoidCallback onYoutube;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final tracks =
        ref.watch(searchTracksProvider(text)).value ?? const <Track>[];
    final res = searchLibrary(
      text: text,
      tracks: tracks,
      artists: ref.watch(artistsProvider).value ?? const [],
      albums: ref.watch(albumsProvider).value ?? const [],
      playlists: ref.watch(playlistsProvider).value ?? const [],
    );
    final ctrl = ref.read(playerControllerProvider);
    final compact = ref.watch(settingsProvider).compactMode;
    final extent = trackRowExtentOf(context, compact);
    const key = 'search';
    final selection = RowSelection(
      listKey: key,
      visibleIds: [for (final t in res.tracks) t.id],
    );

    void openArtist(ArtistSummary a) =>
        ShellNav.open<void>(context, ArtistDetailScreen(artist: a));
    void openAlbum(AlbumSummary a) =>
        ShellNav.open<void>(context, AlbumDetailScreen(album: a));

    Widget mainCard() {
      final m = res.main;
      Widget leading;
      String title;
      String subtitle;
      VoidCallback tap;
      if (m is ArtistSummary) {
        leading = ArtistAvatar(name: m.name, size: 64, coverKey: m.coverKey);
        title = m.name ?? l.unknownArtist;
        subtitle = l.kindArtist;
        tap = () => openArtist(m);
      } else if (m is AlbumSummary) {
        leading = CoverImage(
          coverKey: m.coverKey,
          size: 64,
          radius: CcDims.rGrid,
        );
        title = m.title ?? l.unknownAlbum;
        subtitle = '${l.kindAlbum} · ${m.artist ?? l.unknownArtist}';
        tap = () => openAlbum(m);
      } else {
        final t = m! as Track;
        leading = CoverImage(
          coverKey: t.coverKey,
          size: 64,
          radius: CcDims.rGrid,
        );
        title = t.title;
        subtitle = t.artist ?? l.unknownArtist;
        tap = () => ctrl.playFromList(
          [t],
          0,
          context: const PlayContext(PlayContextKind.search),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
        child: Material(
          color: cc.surface1,
          borderRadius: BorderRadius.circular(CcDims.rCard),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: tap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleMedium,
                        ),
                        Text(subtitle, style: theme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget row(
      Widget leading,
      String title,
      String subtitle,
      VoidCallback tap,
    ) => InkWell(
      onTap: tap,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: CcDims.margin),
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyLarge,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final results = ListView(
      children: [
        if (res.isEmpty)
          Padding(
            padding: const EdgeInsets.all(CcDims.margin),
            child: Text(
              l.searchEmptyLibrary,
              style: theme.bodyMedium?.copyWith(color: cc.textMuted),
            ),
          )
        else ...[
          SectionHeader(l.searchMainResult),
          mainCard(),
          if (res.tracks.isNotEmpty) ...[
            SectionHeader(l.tracks),
            for (var i = 0; i < res.tracks.length; i++)
              SizedBox(
                height: extent,
                child: LiveTrackRow(
                  track: res.tracks[i],
                  compact: compact,
                  selection: selection,
                  onTap: () => ctrl.playFromList(
                    tracks,
                    i,
                    context: const PlayContext(PlayContextKind.search),
                  ),
                ),
              ),
            if (res.trackTotal > res.tracks.length)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: CcDims.margin - 8),
                  child: TextButton(
                    onPressed: () => ShellNav.open<void>(
                      context,
                      SearchTracksScreen(text: text),
                    ),
                    child: Text(l.showAll),
                  ),
                ),
              ),
          ],
          if (res.artists.isNotEmpty) ...[
            SectionHeader(l.artists),
            SizedBox(
              height: 124,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: CcDims.margin - 6,
                ),
                itemCount: res.artists.length,
                itemBuilder: (_, i) {
                  final a = res.artists[i];
                  return InkWell(
                    onTap: () => openArtist(a),
                    borderRadius: BorderRadius.circular(CcDims.rGrid),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: SizedBox(
                        width: 92,
                        child: Column(
                          children: [
                            ArtistAvatar(
                              name: a.name,
                              size: 80,
                              coverKey: a.coverKey,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              a.name ?? l.unknownArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodyMedium?.copyWith(color: cc.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (res.albums.isNotEmpty) ...[
            SectionHeader(l.albums),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: CcDims.margin - 6,
                ),
                itemCount: res.albums.length,
                itemBuilder: (_, i) {
                  final a = res.albums[i];
                  return InkWell(
                    onTap: () => openAlbum(a),
                    borderRadius: BorderRadius.circular(CcDims.rGrid),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CoverImage(
                              coverKey: a.coverKey,
                              size: 120,
                              radius: CcDims.rGrid,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              a.title ?? l.unknownAlbum,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodyMedium?.copyWith(color: cc.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (res.playlists.isNotEmpty) ...[
            SectionHeader(l.navPlaylists),
            for (final p in res.playlists)
              row(
                PlaylistCover(
                  size: 40,
                  coverKeys: playlistCoverKeys(p.playlist.coverKey, [
                    p.autoCoverKey,
                  ]),
                ),
                p.playlist.name,
                l.playlistCountLabel(p.trackCount),
                () => ShellNav.open<void>(
                  context,
                  PlaylistDetailScreen(playlist: p.playlist),
                ),
              ),
          ],
        ],
        if (kEnableYoutube)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CcDims.margin,
              16,
              CcDims.margin,
              24,
            ),
            child: OutlinedButton.icon(
              onPressed: onYoutube,
              icon: const Icon(Icons.smart_display_outlined),
              label: Text(
                l.searchOnYoutube(text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
    return SelectionScope(
      listKey: key,
      visibleIds: selection.visibleIds,
      child: Column(
        children: [
          SelectionBarSlot(
            listKey: key,
            tracks: res.tracks,
            belowStatusBar: false,
          ),
          Expanded(child: results),
        ],
      ),
    );
  }
}

/// «Mostra tutti»: every track matching the text.
class SearchTracksScreen extends ConsumerWidget {
  const SearchTracksScreen({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tracks =
        ref.watch(searchTracksProvider(text)).value ?? const <Track>[];
    final ctrl = ref.read(playerControllerProvider);
    final compact = ref.watch(settingsProvider).compactMode;
    const key = 'search-all';
    final selection = RowSelection(
      listKey: key,
      visibleIds: [for (final t in tracks) t.id],
    );
    return SelectionScope(
      listKey: key,
      visibleIds: selection.visibleIds,
      child: Scaffold(
        appBar: SelectableAppBar(
          listKey: key,
          tracks: tracks,
          normal: AppBar(title: Text(l.tracks)),
        ),
        body: ListView.builder(
          itemExtent: trackRowExtentOf(context, compact),
          itemCount: tracks.length,
          itemBuilder: (_, i) => LiveTrackRow(
            track: tracks[i],
            compact: compact,
            selection: selection,
            onTap: () => ctrl.playFromList(
              tracks,
              i,
              context: const PlayContext(PlayContextKind.search),
            ),
          ),
        ),
      ),
    );
  }
}
