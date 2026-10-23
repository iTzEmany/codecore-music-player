import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/selection_providers.dart';
import '../../../providers/youtube_providers.dart';
import '../../../services/online/merge_results.dart';
import '../../../services/online/query_match.dart' show MediaKind;
import '../../../services/online/smart_search.dart';
import '../../../services/online/ytm_artist.dart';
import '../../theme/tokens.dart';
import '../../widgets/segmented_blocks.dart';
import '../online/online_song_row.dart';
import 'listen_bar.dart';

String sourceName(AppLocalizations l, MediaKind k) => switch (k) {
  MediaKind.ytmSong => l.searchSourceYoutubeMusic,
  MediaKind.ytVideo => l.searchSourceYoutube,
};

/// «Tutte, YouTube Music, YouTube»: a filter on the rows already there.
class SourceFilterChips extends StatelessWidget {
  const SourceFilterChips({
    super.key,
    required this.filter,
    required this.onPick,
  });

  final MediaKind? filter;
  final ValueChanged<MediaKind?> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 0, CcDims.margin, 8),
      child: SegmentedBlocks<MediaKind?>(
        selected: filter,
        onChanged: onPick,
        items: [
          BlockItem(
            value: null,
            icon: Icons.apps_rounded,
            label: l.onlineFilterAll,
          ),
          BlockItem(
            value: MediaKind.ytmSong,
            icon: Icons.music_note_rounded,
            label: sourceName(l, MediaKind.ytmSong),
          ),
          BlockItem(
            value: MediaKind.ytVideo,
            icon: Icons.smart_display_rounded,
            label: sourceName(l, MediaKind.ytVideo),
          ),
        ],
      ),
    );
  }
}

/// One line per source that gave nothing, above the list.
class SearchNotices extends StatelessWidget {
  const SearchNotices({super.key, required this.notices});

  final List<SearchNotice> notices;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.cc.textMuted);
    String text(SearchNotice n) {
      final source = sourceName(l, n.source);
      final other = sourceName(
        l,
        MediaKind.values.firstWhere((k) => k != n.source),
      );
      return switch (n.kind) {
        NoticeKind.rateLimited => l.onlineNoticeRateLimited(source, other),
        NoticeKind.offline => l.ytErrNetwork,
        NoticeKind.failed => l.onlineNoticeFailed(source, other),
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final n in notices)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CcDims.margin,
              0,
              CcDims.margin,
              6,
            ),
            child: Text(
              text(n),
              key: ValueKey('notice-${n.source.name}'),
              style: style,
            ),
          ),
      ],
    );
  }
}

/// «Altri risultati (N)»: opens the list of the less sure rows below it.
class OthersChip extends StatelessWidget {
  const OthersChip({
    super.key,
    required this.count,
    required this.open,
    required this.onTap,
  });

  final int count;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 8, CcDims.margin, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          key: const ValueKey('others-chip'),
          avatar: Icon(
            open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          ),
          label: Text(context.l10n.onlineOthersChip(count)),
          onPressed: onTap,
        ),
      ),
    );
  }
}

/// A row of the online results: the song of the best source, a small label of
/// where it comes from and, when there is also a video of it, a tap to listen
/// to that. [index] is its place in the list picks refer to.
class SmartRow extends ConsumerWidget {
  const SmartRow({
    super.key,
    required this.row,
    required this.index,
    required this.selectionKey,
    required this.onArtistTap,
    required this.onListenVideo,
  });

  final SmartResult row;
  final int index;
  final String selectionKey;
  final void Function(YtmArtistRef artist)? onArtistTap;
  final VoidCallback onListenVideo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final r = row.primary;
    final picked = ref.watch(selectionProvider(selectionKey));
    final notifier = ref.read(selectionProvider(selectionKey).notifier);
    final ids = row.ids.toSet();
    final inLibrary = ref.watch(
      downloadIndexProvider.select(
        (i) =>
            ids.any((id) => i.value?.contains(id, source: r.source) ?? false),
      ),
    );
    final item = ref.watch(
      downloadsProvider.select(
        (d) => d.where((x) => ids.contains(x.result.id)).lastOrNull,
      ),
    );
    final selecting = picked.active;
    final who = r.artistIds.indexWhere((id) => id.isNotEmpty);
    final label = row.sources.contains(MediaKind.ytmSong)
        ? l.searchSourceYoutubeMusic
        : l.onlineSourceVideo;
    final small = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: cc.textMuted);
    return OnlineSongRow(
      result: r,
      inLibrary: inLibrary,
      item: item,
      selecting: selecting,
      selected: picked.contains(index),
      position: picked.contains(index) ? picked.positionOf(index) + 1 : null,
      onTap: selecting ? () => notifier.toggle(index) : null,
      onLongPress: () => notifier.toggle(index),
      onDownload: () => ref.read(downloadsProvider.notifier).add(r),
      listen: selecting ? null : ListenButton(result: r),
      onArtistTap: onArtistTap == null || who < 0 || who >= r.artists.length
          ? null
          : () => onArtistTap!(
              YtmArtistRef(id: r.artistIds[who], name: r.artists[who]),
            ),
      tagLine: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: small,
            ),
          ),
          if (row.hasVideo && !selecting) ...[
            Text(', ', style: small),
            Flexible(
              child: Tooltip(
                message: l.onlineListenVideo,
                child: InkWell(
                  key: ValueKey('listen-video-${r.id}'),
                  onTap: onListenVideo,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      l.onlineAlsoVideo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small?.copyWith(
                        color: cc.accentSoft,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
