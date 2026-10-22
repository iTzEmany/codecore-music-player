import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/listen_providers.dart';
import '../../../providers/selection_providers.dart';
import '../../../services/online/youtube_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/activity_button.dart';
import '../../widgets/selection_bar.dart';
import '../youtube/listen_bar.dart';
import 'online_song_row.dart';

/// The frame of every online page (artist, album, long song list): a pinned
/// bar with the activity button, the page's [slivers], the selection bar with
/// «Scarica» while songs are picked, and «Ascolta» at the bottom.
///
/// The page shares the listen of the other online pages: it keeps going while
/// any is open and ends with the last (`ListenNotifier.attach`/`detach`).
class OnlinePageFrame extends ConsumerStatefulWidget {
  const OnlinePageFrame({
    super.key,
    required this.title,
    required this.slivers,
    this.selectionKey,
    this.pickable = const [],
    this.onRefresh,
    this.actions = const [],
  });

  /// Shown in the pinned bar.
  final String title;
  final List<Widget> slivers;

  /// The pick list of the page (`ytm-artist:<id>`); null = songs not pickable.
  /// The songs are ids `0…` of [pickable], in the order shown.
  final String? selectionKey;
  final List<YtResult> pickable;

  /// Pull down to ask again.
  final Future<void> Function()? onRefresh;

  /// Extra buttons of the bar, before the activity button.
  final List<Widget> actions;

  @override
  ConsumerState<OnlinePageFrame> createState() => _OnlinePageFrameState();
}

class _OnlinePageFrameState extends ConsumerState<OnlinePageFrame> {
  late final ListenNotifier _listen;

  @override
  void initState() {
    super.initState();
    _listen = ref.read(listenProvider.notifier)..attach();
  }

  @override
  void dispose() {
    _listen.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final key = widget.selectionKey;
    final picked = key == null ? null : ref.watch(selectionProvider(key));
    final scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: cc.bg,
          surfaceTintColor: Colors.transparent,
          title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [...widget.actions, const ActivityButton(), const SizedBox(width: 8)],
        ),
        ...widget.slivers,
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
    final body = Stack(
      children: [
        Positioned.fill(
          child: widget.onRefresh == null
              ? scroll
              // The spinner starts under the pinned bar, not behind the status bar.
              : RefreshIndicator(
                  onRefresh: widget.onRefresh!,
                  edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
                  child: scroll),
        ),
        if (key != null && picked != null && picked.active)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SelectionBarFrame(
              count: picked.count,
              onClose: ref.read(selectionProvider(key).notifier).clear,
              onSelectAll: () => ref
                  .read(selectionProvider(key).notifier)
                  .selectAll([for (var i = 0; i < widget.pickable.length; i++) i]),
              actions: [
                IconButton(
                  tooltip: l.ytDownload,
                  icon: const Icon(Icons.download_rounded),
                  onPressed: () {
                    startOnlineDownloads(context, ref, [
                      for (final i in picked.orderedIds)
                        if (i < widget.pickable.length) widget.pickable[i],
                    ]);
                    ref.read(selectionProvider(key).notifier).clear();
                  },
                ),
              ],
            ),
          ),
      ],
    );
    return Scaffold(
      backgroundColor: cc.bg,
      body: Column(
        children: [
          Expanded(
            child: key == null
                ? body
                : SelectionScope(
                    listKey: key,
                    visibleIds: [for (var i = 0; i < widget.pickable.length; i++) i],
                    child: body,
                  ),
          ),
          const ListenBar(),
        ],
      ),
    );
  }
}
