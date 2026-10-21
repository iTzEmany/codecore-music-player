import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/listen_providers.dart';
import '../../../providers/selection_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/youtube_providers.dart';
import '../../../providers/ytm_catalog_providers.dart';
import '../../../services/online/ytm_artist.dart';
import '../../../services/online/youtube_service.dart';
import '../../../services/online/youtube_urls.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../online/artist_card.dart';
import '../online/artist_page_screen.dart';
import '../online/online_song_row.dart';
import '../../widgets/activity_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/yt_dlp_outdated_banner.dart';
import 'listen_bar.dart';
import 'playlist_source_sheet.dart';
import '../../widgets/motion.dart';

String ytErrorText(BuildContext context, YtErrorKind k) {
  final l = context.l10n;
  return switch (k) {
    YtErrorKind.unavailable => l.ytErrUnavailable,
    YtErrorKind.network => l.ytErrNetwork,
    YtErrorKind.changed => l.ytErrChanged,
    YtErrorKind.toolMissing => l.ytErrToolMissing,
    YtErrorKind.rateLimited => l.ytErrRateLimited,
    YtErrorKind.toolOutdated => l.ytErrToolOutdated,
  };
}

/// YouTube results for [query]. The search runs only when [submitted]
/// changes (Enter / the arrow / «Cerca su YouTube»), never while typing.
class YoutubeResults extends ConsumerStatefulWidget {
  const YoutubeResults({
    super.key,
    required this.query,
    required this.submitted,
  });

  final String query;
  final int submitted;

  @override
  ConsumerState<YoutubeResults> createState() => _YoutubeResultsState();
}

class _YoutubeResultsState extends ConsumerState<YoutubeResults> {
  /// Results are picked by their position in the list shown.
  static const _selectionKey = 'youtube';
  List<YtResult> _results = const [];
  bool _searching = false;
  bool _searched = false;
  YtErrorKind? _error;
  int _requestId = 0;
  late final ListenNotifier _listen;

  /// The artist behind the top result of the search, when it is one.
  YtmArtistRef? _artist;

  /// A listen has no player of its own outside the online pages: it ends with
  /// the last of them (these results, an artist page opened from them…).
  @override
  void dispose() {
    _listen.detach();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _listen = ref.read(listenProvider.notifier)..attach();
    if (widget.submitted > 0) _search();
  }

  @override
  void didUpdateWidget(YoutubeResults old) {
    super.didUpdateWidget(old);
    if (widget.submitted != old.submitted) _search();
  }

  Future<void> _search() async {
    final q = widget.query.trim();
    if (q.isEmpty) return;
    // A playlist or channel address is not a search: it opens its video list.
    final listing = listingUrl(q);
    if (listing != null) {
      // After the frame: a sheet cannot be opened while the page is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) PlaylistSourceSheet.show(context, listing);
      });
      return;
    }
    final id = ++_requestId;
    setState(() {
      _searching = true;
      _error = null;
      _artist = null;
    });
    try {
      final service = ref.read(youtubeServiceProvider);
      final source = ref.read(settingsProvider).searchSource;
      // In parallel, never in the way of the results.
      if (source != SearchSource.soundcloud) unawaited(_loadArtistCard(q, id));
      final watch = Stopwatch()..start();
      final res = switch (source) {
        SearchSource.youtube => await service.search(q),
        SearchSource.youtubeMusic => await service.searchSongs(q, limit: 10),
        SearchSource.soundcloud => await service.searchSoundCloud(q, limit: 10),
      };
      AppLog.i('search ${source.name}: ${res.length} results in '
          '${watch.elapsedMilliseconds} ms');
      if (!mounted || id != _requestId) return;
      // Picks refer to rows of the old results.
      ref.read(selectionProvider(_selectionKey).notifier).clear();
      setState(() {
        _results = res;
        _searched = true;
      });
    } on YtException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() => _error = e.kind);
    } finally {
      if (mounted && id == _requestId) setState(() => _searching = false);
    }
  }

  /// The artist card: only when YouTube Music's top result is an artist; a
  /// failure is logged, never shown. A late answer to an old search is dropped.
  Future<void> _loadArtistCard(String q, int id) async {
    try {
      final artist = await ref
          .read(ytmCatalogProvider)
          .topArtist(q, ref.read(ytmLanguageProvider));
      if (!mounted || id != _requestId) return;
      setState(() => _artist = artist);
    } on Object catch (e) {
      AppLog.w('artist card: not available ($e)');
    }
  }

  void _openArtist(YtmArtistRef artist) =>
      ShellNav.open<void>(context, ArtistPageScreen(artist: artist));

  void _pickSource(SearchSource s) {
    if (ref.read(settingsProvider).searchSource == s) return;
    ref.read(settingsProvider.notifier).update((c) => c.copyWith(searchSource: s));
    // The same words on another source: ask again when there is something to ask.
    if (_searched && widget.query.trim().isNotEmpty) _search();
  }

  /// Starts a download for each picked result that is not already in the
  /// library or on its way.
  void _downloadSelection() {
    final picked = ref.read(selectionProvider(_selectionKey));
    startOnlineDownloads(context, ref, [
      for (final i in picked.orderedIds)
        if (i < _results.length) _results[i],
    ]);
    ref.read(selectionProvider(_selectionKey).notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    ref.listen(listenProvider.select((s) => s.error), (_, error) {
      if (error == null) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(ytErrorText(context, error))));
    });
    final seen = ref.watch(settingsProvider.select((s) => s.ytNoticeSeen));
    final source = ref.watch(settingsProvider.select((s) => s.searchSource));
    final picked = ref.watch(selectionProvider(_selectionKey));
    final downloads = ref.watch(downloadsProvider);
    final index = ref.watch(downloadIndexProvider).value;
    final theme = Theme.of(context).textTheme;
    final shownIds = [for (var i = 0; i < _results.length; i++) i];
    final selecting = picked.active;
    return SelectionScope(
      listKey: _selectionKey,
      visibleIds: shownIds,
      child: Column(
        children: [
          if (selecting)
            SelectionBarFrame(
              count: picked.count,
              belowStatusBar: false,
              onClose: ref
                  .read(selectionProvider(_selectionKey).notifier)
                  .clear,
              onSelectAll: () => ref
                  .read(selectionProvider(_selectionKey).notifier)
                  .selectAll(shownIds),
              actions: [
                IconButton(
                  tooltip: l.ytDownload,
                  icon: const Icon(Icons.download_rounded),
                  onPressed: _downloadSelection,
                ),
              ],
            ),
          const YtDlpOutdatedBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(CcDims.margin, 4, CcDims.margin, 0),
            child: Wrap(
              spacing: 8,
              children: [
                for (final s in SearchSource.values)
                  ChoiceChip(
                    key: ValueKey('source-${s.name}'),
                    label: Text(switch (s) {
                      SearchSource.youtube => l.searchSourceYoutube,
                      SearchSource.youtubeMusic => l.searchSourceYoutubeMusic,
                      SearchSource.soundcloud => l.searchSourceSoundcloud,
                    }),
                    selected: source == s,
                    onSelected: (_) => _pickSource(s),
                  ),
              ],
            ),
          ),
          if (!seen)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CcDims.margin,
                4,
                CcDims.margin,
                8,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cc.surface1,
                  borderRadius: BorderRadius.circular(CcDims.rCard),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(l.ytLegal, style: theme.bodyMedium)),
                    TextButton(
                      onPressed: () => ref
                          .read(settingsProvider.notifier)
                          .update((s) => s.copyWith(ytNoticeSeen: true)),
                      child: Text(l.gotIt),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
            child: Row(
              children: [
                if (seen)
                  IconButton(
                    tooltip: l.ytInfoTooltip,
                    icon: const Icon(Icons.info_outline_rounded),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        content: Text(l.ytLegal),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text(l.close),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                const ActivityButton(),
              ],
            ),
          ),
          if (_searching) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                ytErrorText(context, _error!),
                style: TextStyle(color: cc.error),
              ),
            ),
          Expanded(
            child: _results.isEmpty && _artist == null
                ? EmptyState(
                    icon: Icons.smart_display,
                    message: _searched ? l.ytNoResults : l.ytSearchPrompt,
                  )
                : EntranceScope(
                    // A new search is a new list: its rows come in again.
                    key: ValueKey(_requestId),
                    child: ListView.builder(
                      itemCount: _results.length + (_artist == null ? 0 : 1),
                      itemBuilder: (_, k) {
                        final artist = _artist;
                        if (artist != null && k == 0) {
                          return EnterOnce(
                            index: 0,
                            child: ArtistCard(
                              artist: artist,
                              onTap: () => _openArtist(artist),
                            ),
                          );
                        }
                        final i = artist == null ? k : k - 1;
                        final r = _results[i];
                        final inLibrary =
                            index?.contains(r.id, source: r.source) ?? false;
                        final item = downloads
                            .where((d) => d.result.id == r.id)
                            .lastOrNull;
                        final notifier = ref.read(
                          selectionProvider(_selectionKey).notifier,
                        );
                        final who = r.artistIds.indexWhere((id) => id.isNotEmpty);
                        return EnterOnce(
                          index: k,
                          child: SizedBox(
                            height: 72,
                            child: OnlineSongRow(
                              result: r,
                              inLibrary: inLibrary,
                              item: item,
                              selecting: selecting,
                              selected: picked.contains(i),
                              position: picked.contains(i)
                                  ? picked.positionOf(i) + 1
                                  : null,
                              onTap: selecting ? () => notifier.toggle(i) : null,
                              onLongPress: () => notifier.toggle(i),
                              onDownload: () =>
                                  ref.read(downloadsProvider.notifier).add(r),
                              listen: selecting ? null : ListenButton(result: r),
                              onArtistTap: who < 0 || who >= r.artists.length
                                  ? null
                                  : () => _openArtist(YtmArtistRef(
                                      id: r.artistIds[who], name: r.artists[who])),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const ListenBar(),
        ],
      ),
    );
  }
}
