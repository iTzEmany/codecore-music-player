import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/player_providers.dart';
import '../../core/platform.dart';
import '../../providers/selection_providers.dart';
import '../theme/tokens.dart';
import 'cover_image.dart';
import 'favorite_actions.dart';
import 'format_utils.dart';
import 'now_playing_bars.dart';
import 'preview_cover.dart';
import 'track_actions.dart';
import 'track_drag.dart';
import 'track_row_selection.dart';

enum TrackRowVariant {
  /// Cover, title, «artist · album».
  standard,

  /// Track number instead of the cover; artist only when it differs.
  album,

  /// Drag handle on the right (needs [TrackRow.reorderIndex]).
  queue,

  /// Round ＋/✓ on the right (selection lists).
  pick,
}

/// The only track row of the app. Fixed height: pair it with `itemExtent`
/// from `trackRowExtentOf`.
class TrackRow extends StatefulWidget {
  const TrackRow({
    super.key,
    required this.track,
    required this.onTap,
    this.variant = TrackRowVariant.standard,
    this.isCurrent = false,
    this.isPlaying = false,
    this.compact = false,
    this.onMore,
    this.onFavorite,
    this.onLongPress,
    this.onSecondaryTap,
    this.index,
    this.albumArtist,
    this.picked = false,
    this.reorderIndex,
    this.selectionMode = false,
    this.selected = false,
  });

  final Track track;
  final VoidCallback onTap;
  final TrackRowVariant variant;
  final bool isCurrent, isPlaying, compact, picked;

  /// The list is in selection mode: a tick box replaces the cover or number,
  /// and a picked row ([selected]) is tinted. Same height either way.
  final bool selectionMode, selected;
  final VoidCallback? onMore, onFavorite, onLongPress;

  /// Right click on desktop; receives the global pointer position.
  final void Function(Offset position)? onSecondaryTap;

  /// 1-based position shown in the wide «#» column (track number if null).
  final int? index;

  /// Album variant: the artist is hidden when it equals this one.
  final String? albumArtist;

  /// Position inside a `ReorderableListView` for the drag handle.
  final int? reorderIndex;

  @override
  State<TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<TrackRow> {
  bool _hover = false;

  /// [albumColumn]: wide rows show the album in its own column, so the
  /// subtitle keeps only the artist.
  String _subtitle(BuildContext context, {bool albumColumn = false}) {
    final t = widget.track;
    final parts = <String>[];
    switch (widget.variant) {
      case TrackRowVariant.album:
        final a = t.artist;
        if (a != null &&
            a.trim().toLowerCase() !=
                (widget.albumArtist ?? '').trim().toLowerCase()) {
          parts.add(a);
        }
      case _:
        if (t.artist != null) parts.add(t.artist!);
        if (!albumColumn && t.album != null) parts.add(t.album!);
    }
    final resume = t.resumePositionMs;
    if (resume != null) {
      parts.add(context.l10n.resumeFrom(formatDuration(resume)));
    }
    return parts.join(' · ');
  }

  Widget _leading(BuildContext context, double cover, {bool bars = true}) {
    final cc = context.cc;
    final t = widget.track;
    if (widget.selectionMode) {
      return SelectionBox(
        selected: widget.selected,
        size: widget.variant == TrackRowVariant.album ? 32 : cover,
      );
    }
    if (widget.variant == TrackRowVariant.album) {
      final n = t.trackNumber;
      return SizedBox(
        width: 32,
        child: Center(
          child: widget.isCurrent
              ? NowPlayingBars(playing: widget.isPlaying, size: 16)
              : Text(
                  n == null ? '' : '$n',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
        ),
      );
    }
    final plain = CoverImage(coverKey: t.coverKey, size: cover);
    // Hold the cover for a 20 s preview (not in selection lists).
    final image = widget.variant == TrackRowVariant.pick
        ? plain
        : PreviewCover(track: t, size: cover, child: plain);
    if (!widget.isCurrent || !bars) return image;
    return Stack(
      alignment: Alignment.center,
      children: [
        image,
        Container(
          width: cover,
          height: cover,
          decoration: BoxDecoration(
            color: cc.bg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(CcDims.rList),
          ),
          alignment: Alignment.center,
          child: NowPlayingBars(playing: widget.isPlaying, size: cover * 0.4),
        ),
      ],
    );
  }

  /// Wide rows end with [heart slot] [duration] [more slot]: fixed widths so
  /// the columns line up whether or not the actions are visible.
  Widget _wideTail(BuildContext context) {
    final cc = context.cc;
    final l = context.l10n;
    final theme = Theme.of(context).textTheme;
    final fav = widget.track.isFavorite;
    final showHeart = _hover || fav;
    if (widget.variant == TrackRowVariant.pick ||
        widget.variant == TrackRowVariant.queue) {
      return Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              formatDuration(widget.track.durationMs),
              textAlign: TextAlign.end,
              style: theme.labelSmall,
            ),
          ),
          _trailing(context, true),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          child: showHeart && widget.onFavorite != null
              ? IconButton(
                  tooltip: fav ? l.removeFromFavorites : l.favorite,
                  onPressed: widget.onFavorite,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    fav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: fav ? cc.accent : cc.textMuted,
                  ),
                )
              : null,
        ),
        SizedBox(
          width: 56,
          child: Text(
            formatDuration(widget.track.durationMs),
            textAlign: TextAlign.center,
            style: theme.labelSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: widget.onMore == null
              ? null
              : Opacity(
                  opacity: _hover ? 1 : 0,
                  child: IconButton(
                    tooltip: l.moreOptions,
                    onPressed: widget.onMore,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.more_horiz_rounded, color: cc.textMuted),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _trailing(BuildContext context, bool wide) {
    final cc = context.cc;
    final l = context.l10n;
    final fav = widget.track.isFavorite;
    switch (widget.variant) {
      case TrackRowVariant.pick:
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Icon(
            widget.picked
                ? Icons.check_circle_rounded
                : Icons.add_circle_outline_rounded,
            color: widget.picked ? cc.accent : cc.textMuted,
          ),
        );
      case TrackRowVariant.queue:
        final i = widget.reorderIndex;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: i == null
              ? Icon(Icons.drag_handle_rounded, color: cc.textMuted)
              : ReorderableDragStartListener(
                  index: i,
                  child: Icon(Icons.drag_handle_rounded, color: cc.textMuted),
                ),
        );
      case _:
    }
    final showActions = !wide || _hover || fav;
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (wide && (_hover || fav) && widget.onFavorite != null)
          IconButton(
            tooltip: fav ? l.removeFromFavorites : l.favorite,
            onPressed: widget.onFavorite,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18,
              color: fav ? cc.accent : cc.textMuted,
            ),
          )
        else if (fav)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.favorite_rounded, size: 16, color: cc.accent),
          ),
        if (widget.onMore != null)
          Opacity(
            opacity: showActions ? 1 : 0,
            child: IconButton(
              tooltip: l.moreOptions,
              onPressed: widget.onMore,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                wide ? Icons.more_horiz_rounded : Icons.more_vert_rounded,
                color: cc.textMuted,
              ),
            ),
          ),
      ],
    );
    // Same width whether or not the actions show, so the columns line up.
    return wide
        ? SizedBox(
            width: 96,
            child: Align(alignment: Alignment.centerRight, child: actions),
          )
        : actions;
  }

  /// Columns (# · title · album · duration) only when the row itself is wide
  /// enough: the desktop side panel is 320 px inside a wide window.
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => _row(
      context,
      MediaQuery.sizeOf(context).width >= CcDims.wideBreakpoint &&
          c.maxWidth >= 520,
    ),
  );

  Widget _row(BuildContext context, bool wide) {
    final cc = context.cc;
    final theme = Theme.of(context);
    final t = widget.track;
    final subtitle = _subtitle(
      context,
      albumColumn: wide && widget.variant != TrackRowVariant.pick,
    );
    final cover = widget.compact ? 40.0 : 48.0;
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      color: widget.isCurrent ? cc.accent : cc.text,
    );

    final titleBlock = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
      ],
    );

    final Widget row;
    if (wide && widget.variant != TrackRowVariant.pick) {
      final num = widget.variant == TrackRowVariant.album
          ? t.trackNumber
          : widget.index;
      row = Row(
        children: [
          SizedBox(
            width: 40,
            child: widget.selectionMode
                ? SelectionBox(selected: widget.selected, size: 40)
                : widget.isCurrent
                ? Center(
                    child: NowPlayingBars(playing: widget.isPlaying, size: 16),
                  )
                : Center(
                    child: Text(
                      num == null ? '' : '$num',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
          ),
          if (widget.variant != TrackRowVariant.album) ...[
            // The bars already sit in the number column.
            if (widget.selectionMode)
              CoverImage(coverKey: t.coverKey, size: cover)
            else
              _leading(context, cover, bars: false),
            const SizedBox(width: 12),
          ],
          Expanded(flex: 5, child: titleBlock),
          if (widget.variant != TrackRowVariant.album) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                t.album ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
          _wideTail(context),
        ],
      );
    } else {
      row = Row(
        children: [
          _leading(context, cover),
          const SizedBox(width: 12),
          Expanded(child: titleBlock),
          _trailing(context, false),
        ],
      );
    }

    final tint = widget.selected
        ? cc.accentSoft.withValues(alpha: 0.16)
        : _hover && wide
        ? cc.surface2.withValues(alpha: 0.5)
        : Colors.transparent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        selected: widget.selectionMode ? widget.selected : null,
        value: widget.selected ? context.l10n.selectedRow : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: widget.onSecondaryTap == null
              ? null
              : (d) => widget.onSecondaryTap!(d.globalPosition),
          child: Material(
            color: tint,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
                child: row,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rebuilds only when this row's «current / playing» state changes.
class LiveTrackRow extends ConsumerWidget {
  const LiveTrackRow({
    super.key,
    required this.track,
    required this.onTap,
    this.variant = TrackRowVariant.standard,
    this.compact = false,
    this.index,
    this.albumArtist,
    this.onMore,
    this.reorderIndex,
    this.selection,
  });

  final Track track;
  final VoidCallback onTap;
  final TrackRowVariant variant;
  final bool compact;
  final int? index;
  final String? albumArtist;

  /// Makes the row pickable together with the others of its list (long press
  /// on a phone, Ctrl or Shift + click on a desktop).
  final RowSelection? selection;

  /// Replaces the default actions sheet (e.g. «Rimuovi dalla playlist»).
  final VoidCallback? onMore;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = ref.watch(
      currentTrackProvider.select((t) => t.value?.id == track.id),
    );
    final playing = isCurrent && (ref.watch(isPlayingProvider).value ?? false);
    void actions() => showTrackActions(context, ref, track);
    final sel = selection;
    final (active, picked) = sel == null
        ? (false, false)
        : ref.watch(
            selectionProvider(sel.listKey)
                .select((s) => (s.active, s.contains(track.id))),
          );
    void tap() {
      if (sel == null) return onTap();
      final keys = HardwareKeyboard.instance;
      final shift = keys.isShiftPressed;
      if (!active && !shift && !keys.isControlPressed && !keys.isMetaPressed) {
        return onTap();
      }
      final notifier = ref.read(selectionProvider(sel.listKey).notifier);
      shift
          ? notifier.selectRange(sel.visibleIds, track.id)
          : notifier.toggle(track.id);
    }

    // A phone picks with a long press; a desktop keeps the menu there.
    final phone = switch (Theme.of(context).platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => true,
      _ => false,
    };
    void longPress() {
      if (sel == null || !phone) return actions();
      HapticFeedback.selectionClick();
      ref.read(selectionProvider(sel.listKey).notifier).toggle(track.id);
    }

    final row = TrackRow(
      track: track,
      variant: variant,
      isCurrent: isCurrent,
      isPlaying: playing,
      onTap: tap,
      onMore: onMore ?? actions,
      onLongPress: longPress,
      selectionMode: active,
      selected: picked,
      onSecondaryTap: (pos) => showTrackContextMenu(context, ref, track, pos),
      onFavorite: () => toggleFavorite(context, ref, track),
      compact: compact,
      index: index,
      albumArtist: albumArtist,
      reorderIndex: reorderIndex,
    );
    // On a desktop a row can be dragged onto a playlist of the sidebar: the
    // whole selection when the row is part of it, otherwise just this track.
    Widget draggable(Widget child) {
      if (sel == null || !isDesktop) return child;
      List<int> ids() {
        final s = ref.read(selectionProvider(sel.listKey));
        return s.active && s.contains(track.id)
            ? s.inOrderOf(sel.visibleIds)
            : [track.id];
      }

      return Draggable<TrackDragData>(
        data: TrackDragData(ids),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: DragPill(countOf: () => ids().length),
        child: child,
      );
    }

    // Queue and pick rows have their own gestures.
    if (variant == TrackRowVariant.queue || variant == TrackRowVariant.pick) {
      return row;
    }
    if (active) return draggable(row);
    return Dismissible(
      key: ValueKey('swipe-queue-${track.id}'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.3},
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: context.cc.surface2,
        child: Icon(Icons.queue_rounded, color: context.cc.accentSoft),
      ),
      // The row always comes back; only the queue changes.
      confirmDismiss: (_) async {
        ref.read(playerControllerProvider).addToQueue(track.id);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(context.l10n.addedToQueue)));
        return false;
      },
      child: draggable(row),
    );
  }
}
