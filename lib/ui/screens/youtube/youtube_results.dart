import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/selection_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/youtube_providers.dart';
import '../../../services/online/download_queue.dart';
import '../../../services/online/youtube_service.dart';
import '../../../services/online/youtube_urls.dart';
import '../../theme/tokens.dart';
import '../../widgets/activity_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/track_row_selection.dart';
import '../../widgets/yt_dlp_outdated_banner.dart';
import 'playlist_source_sheet.dart';

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

  @override
  void initState() {
    super.initState();
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
    });
    try {
      final service = ref.read(youtubeServiceProvider);
      final source = ref.read(settingsProvider).searchSource;
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

  void _pickSource(SearchSource s) {
    if (ref.read(settingsProvider).searchSource == s) return;
    ref.read(settingsProvider.notifier).update((c) => c.copyWith(searchSource: s));
    // The same words on another source: ask again when there is something to ask.
    if (_searched && widget.query.trim().isNotEmpty) _search();
  }

  /// Starts a download for each picked result that is not already in the
  /// library or on its way.
  void _downloadSelection() {
    final l = context.l10n;
    final picked = ref.read(selectionProvider(_selectionKey));
    final index = ref.read(downloadIndexProvider).value;
    final busy = {
      for (final d in ref.read(downloadsProvider))
        if (d.status == DownloadStatus.queued ||
            d.status == DownloadStatus.downloading ||
            d.status == DownloadStatus.waitingRetry)
          d.result.id,
    };
    var started = 0, skipped = 0;
    // In the order the results were picked: that is the order of the queue.
    for (final i in picked.orderedIds) {
      if (i >= _results.length) continue;
      final r = _results[i];
      if ((index?.contains(r.id, source: r.source) ?? false) ||
          busy.contains(r.id)) {
        skipped++;
        continue;
      }
      ref.read(downloadsProvider.notifier).add(r);
      started++;
    }
    ref.read(selectionProvider(_selectionKey).notifier).clear();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            started == 0
                ? l.ytNothingToDownload
                : skipped == 0
                ? l.ytDownloadsStarted(started)
                : l.ytDownloadsSkipped(started, skipped),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
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
            child: _results.isEmpty
                ? EmptyState(
                    icon: Icons.smart_display,
                    message: _searched ? l.ytNoResults : l.ytSearchPrompt,
                  )
                : ListView.builder(
                    itemExtent: 72,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      final inLibrary =
                          index?.contains(r.id, source: r.source) ?? false;
                      final item = downloads
                          .where((d) => d.result.id == r.id)
                          .lastOrNull;
                      final notifier = ref.read(
                        selectionProvider(_selectionKey).notifier,
                      );
                      return _ResultRow(
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.result,
    required this.inLibrary,
    required this.item,
    required this.onDownload,
    this.selecting = false,
    this.selected = false,
    this.position,
    this.onTap,
    this.onLongPress,
  });

  final YtResult result;
  final bool inLibrary;
  final DownloadItem? item;
  final VoidCallback onDownload;

  /// While picking, a tick box leads the row and a tap picks or drops it.
  final bool selecting, selected;

  /// Place in the order of the picks (1-based) of a picked row.
  final int? position;
  final VoidCallback? onTap, onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final meta = [
      result.channel,
      if (result.duration != null)
        formatDuration(result.duration!.inMilliseconds),
    ].join(' · ');
    final st = item?.status;
    final Widget trailing;
    if (st == DownloadStatus.queued ||
        st == DownloadStatus.downloading ||
        st == DownloadStatus.waitingRetry) {
      trailing = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          value: st == DownloadStatus.downloading ? item!.progress : null,
        ),
      );
    } else if (st == DownloadStatus.done || inLibrary) {
      trailing = Icon(Icons.check_circle_rounded, color: cc.accentSoft);
    } else if (st == DownloadStatus.failed) {
      trailing = IconButton(
        tooltip: l.retry,
        icon: Icon(Icons.warning_amber_rounded, color: cc.error),
        onPressed: onDownload,
      );
    } else {
      trailing = IconButton(
        tooltip: l.ytDownload,
        icon: const Icon(Icons.download_rounded),
        onPressed: onDownload,
      );
    }
    return Semantics(
      selected: selecting ? selected : null,
      value: selected
          ? (position == null ? l.selectedRow : l.selectedRowAt(position!))
          : null,
      child: Material(
        color: selected
            ? cc.accentSoft.withValues(alpha: 0.16)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                if (selecting)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: SelectionBox(
                      selected: selected,
                      position: position,
                      size: 40,
                    ),
                  )
                else
                  const SizedBox(width: CcDims.margin),
                ClipRRect(
                  borderRadius: BorderRadius.circular(CcDims.rList),
                  child: SizedBox(
                    width: 80,
                    height: 45,
                    child: result.thumbnailUrl == null
                        ? ColoredBox(
                            color: cc.surface3,
                            child: Icon(Icons.music_video, color: cc.textMuted),
                          )
                        : Image.network(
                            result.thumbnailUrl!,
                            cacheWidth: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => ColoredBox(
                              color: cc.surface3,
                              child: Icon(
                                Icons.music_video,
                                color: cc.textMuted,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyLarge,
                      ),
                      Row(
                        children: [
                          Icon(
                            result.source == MediaSource.soundcloud
                                ? Icons.cloud_rounded
                                : Icons.smart_display_rounded,
                            key: ValueKey('from-${result.source.name}'),
                            size: 14,
                            color: cc.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      if (inLibrary)
                        Text(
                          l.ytAlreadyInLibrary,
                          style: theme.labelSmall?.copyWith(
                            color: cc.accentSoft,
                          ),
                        ),
                    ],
                  ),
                ),
                trailing,
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
