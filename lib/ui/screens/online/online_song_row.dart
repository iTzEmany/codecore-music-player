import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/selection_providers.dart';
import '../../../providers/youtube_providers.dart';
import '../../../services/online/download_queue.dart';
import '../../../services/online/youtube_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/net_thumbnail.dart';
import '../../widgets/track_row_selection.dart';
import '../youtube/listen_bar.dart';

/// Starts a download for each of [picked] (in this order) that is not already
/// in the library or on its way, and says how many started and how many not.
void startOnlineDownloads(BuildContext context, WidgetRef ref, Iterable<YtResult> picked) {
  final l = context.l10n;
  final index = ref.read(downloadIndexProvider).value;
  final busy = {
    for (final d in ref.read(downloadsProvider))
      if (d.status == DownloadStatus.queued ||
          d.status == DownloadStatus.downloading ||
          d.status == DownloadStatus.waitingRetry)
        d.result.id,
  };
  var started = 0, skipped = 0;
  for (final r in picked) {
    if ((index?.contains(r.id, source: r.source) ?? false) || busy.contains(r.id)) {
      skipped++;
      continue;
    }
    ref.read(downloadsProvider.notifier).add(r);
    started++;
  }
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

/// A song of an artist page, an album or a long list: the row, with its
/// download state, «Già in libreria» and the pick state of list [selectionKey]
/// (the song is id [index] of that list).
class OnlineSongTile extends ConsumerWidget {
  const OnlineSongTile({
    super.key,
    required this.result,
    required this.index,
    required this.selectionKey,
    this.ownedLocally = false,
    this.number,
  });

  final YtResult result;
  final int index;
  final String selectionKey;

  /// Found among the library's songs of the artist (a file, another video).
  final bool ownedLocally;

  /// Place on the record, shown instead of the picture.
  final int? number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = ref.watch(selectionProvider(selectionKey));
    final notifier = ref.read(selectionProvider(selectionKey).notifier);
    final inLibrary = ownedLocally ||
        (ref.watch(downloadIndexProvider).value?.contains(result.id, source: result.source) ?? false);
    final item = ref.watch(downloadsProvider.select(
        (d) => d.where((x) => x.result.id == result.id).lastOrNull));
    final selecting = picked.active;
    return OnlineSongRow(
      result: result,
      inLibrary: inLibrary,
      item: item,
      selecting: selecting,
      selected: picked.contains(index),
      position: picked.contains(index) ? picked.positionOf(index) + 1 : null,
      number: number,
      square: true,
      onTap: selecting ? () => notifier.toggle(index) : null,
      onLongPress: () => notifier.toggle(index),
      onDownload: () => ref.read(downloadsProvider.notifier).add(result),
      listen: selecting ? null : ListenButton(result: result),
    );
  }
}

/// One online song: picture, title, artist and length, «Ascolta» and
/// «Scarica» (or the state of the download), 72 px tall.
class OnlineSongRow extends StatelessWidget {
  const OnlineSongRow({
    super.key,
    required this.result,
    required this.inLibrary,
    required this.item,
    required this.onDownload,
    this.listen,
    this.selecting = false,
    this.selected = false,
    this.position,
    this.onTap,
    this.onLongPress,
    this.onArtistTap,
    this.square = false,
    this.number,
    this.note,
    this.tagLine,
  });

  final YtResult result;
  final bool inLibrary;
  final DownloadItem? item;
  final VoidCallback onDownload;

  /// «Ascolta» (hidden while picking).
  final Widget? listen;

  /// While picking, a tick box leads the row and a tap picks or drops it.
  final bool selecting, selected;

  /// Place in the order of the picks (1-based) of a picked row.
  final int? position;
  final VoidCallback? onTap, onLongPress;

  /// Makes the artist's name a button that opens the artist.
  final VoidCallback? onArtistTap;

  /// A square cover (songs of a record) instead of the 16:9 video picture.
  final bool square;

  /// Place on the record, shown in the picture's place.
  final int? number;

  /// A line under the artist (replaces «Già in libreria»).
  final String? note;

  /// A small line of its own under the artist (where the song comes from),
  /// before «Già in libreria».
  final Widget? tagLine;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final length = result.duration == null
        ? null
        : formatDuration(result.duration!.inMilliseconds);
    final artist = result.artists.isEmpty ? '' : result.artists.first;
    final linked = onArtistTap != null && artist.isNotEmpty;
    final meta = [if (!linked) result.channel, ?length].join(' · ');
    final st = item?.status;
    final Widget trailing;
    if (st == DownloadStatus.queued ||
        st == DownloadStatus.downloading ||
        st == DownloadStatus.waitingRetry) {
      // As wide as a button: «Ascolta» keeps its place on every row.
      trailing = SizedBox(
        width: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              value: st == DownloadStatus.downloading ? item!.progress : null,
            ),
          ),
        ),
      );
    } else if (st == DownloadStatus.done || inLibrary) {
      trailing = SizedBox(
        width: 48,
        child: Center(child: Icon(Icons.check_circle_rounded, color: cc.accentSoft)),
      );
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
        color: selected ? cc.accentSoft.withValues(alpha: 0.16) : Colors.transparent,
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
                    child: SelectionBox(selected: selected, position: position, size: 40),
                  )
                else
                  const SizedBox(width: CcDims.margin),
                if (number != null && !selecting)
                  SizedBox(
                    width: 32,
                    child: Text('$number',
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium?.copyWith(color: cc.textMuted)),
                  )
                else if (square)
                  NetThumbnail(
                      url: result.thumbnailUrl, width: 48, height: 48, icon: Icons.music_note)
                else
                  NetThumbnail(
                      url: result.thumbnailUrl, width: 80, height: 45, icon: Icons.music_video),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.bodyLarge),
                      Row(
                        children: [
                          Icon(
                            Icons.smart_display_rounded,
                            key: ValueKey('from-${result.source.name}'),
                            size: 14,
                            color: cc.textMuted,
                          ),
                          const SizedBox(width: 4),
                          if (linked)
                            Flexible(
                              child: InkWell(
                                key: ValueKey('artist-link-${result.id}'),
                                onTap: onArtistTap,
                                child: Text(artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.bodyMedium?.copyWith(
                                      color: cc.accentSoft,
                                      decoration: TextDecoration.underline,
                                      decorationColor: cc.accentSoft,
                                    )),
                              ),
                            ),
                          if (meta.isNotEmpty)
                            Flexible(
                              fit: linked ? FlexFit.loose : FlexFit.tight,
                              child: Text(linked ? ' · $meta' : meta,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.bodyMedium),
                            ),
                        ],
                      ),
                      if (note != null)
                        Text(note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.labelSmall?.copyWith(color: cc.textMuted))
                      else if (tagLine != null || inLibrary)
                        Row(children: [
                          if (tagLine != null) Flexible(child: tagLine!),
                          if (tagLine != null && inLibrary) const SizedBox(width: 8),
                          if (inLibrary)
                            Flexible(
                              child: Text(l.ytAlreadyInLibrary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.labelSmall?.copyWith(color: cc.accentSoft)),
                            ),
                        ]),
                    ],
                  ),
                ),
                ?listen,
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
