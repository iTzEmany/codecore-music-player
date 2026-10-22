import 'package:flutter/material.dart';

import '../../l10n/l10n_ext.dart';
import '../theme/tokens.dart';
import 'play_buttons.dart';
import 'shuffle_button.dart';

/// Page of one collection (album, artist, playlist, favourites): a pinned bar
/// whose title appears while scrolling, the cover at the left of name and meta
/// (above them when the text is large), then the actions and the page's slivers.
class CollectionScaffold extends StatefulWidget {
  const CollectionScaffold({
    super.key,
    required this.title,
    required this.name,
    this.cover,
    required this.slivers,
    this.coverKey,
    this.subtitle,
    this.meta,
    this.menu,
    this.onPlay,
    this.onShuffle,
    this.barActions = const [],
    this.selectionBar,
  });

  /// Shown in the pinned bar once the big name has scrolled away.
  final String title;
  final String name;

  /// Builds the cover at the given size; null lays out the text only.
  final Widget Function(double size)? cover;
  final List<Widget> slivers;

  /// Identifies the cover (kept for callers).
  final String? coverKey;

  /// A line under the name (e.g. the artist link).
  final Widget? subtitle;
  final String? meta;
  final Widget? menu;
  final VoidCallback? onPlay, onShuffle;
  final List<Widget> barActions;

  /// Laid over the pinned bar while tracks are picked (a `SelectionBarSlot`).
  final Widget? selectionBar;

  @override
  State<CollectionScaffold> createState() => _CollectionScaffoldState();
}

class _CollectionScaffoldState extends State<CollectionScaffold> {
  final _scroll = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final show = _scroll.offset > 220;
      if (show != _showTitle) setState(() => _showTitle = show);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final actions = [
      if (widget.onPlay != null) PlayPill(onPressed: widget.onPlay),
      if (widget.onShuffle != null) ShufflePill(onPressed: widget.onShuffle),
      ?widget.menu,
    ];
    return Scaffold(
      backgroundColor: cc.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: cc.bg,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  title: AnimatedOpacity(
                    duration: ccDuration(context, CcMotion.press),
                    opacity: _showTitle ? 1 : 0,
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  actions: widget.barActions,
                ),
                SliverToBoxAdapter(
                  child: CollectionHeader(
                    cover: widget.cover,
                    name: widget.name,
                    subtitle: widget.subtitle,
                    meta: widget.meta,
                    actions: actions,
                  ),
                ),
                ...widget.slivers,
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
          if (widget.selectionBar != null)
            Positioned(top: 0, left: 0, right: 0, child: widget.selectionBar!),
        ],
      ),
    );
  }
}

/// Cover at the left of name and meta (above them when the text is large),
/// then the actions in a wrapping row. Shared by the local and online pages.
class CollectionHeader extends StatelessWidget {
  const CollectionHeader({
    super.key,
    this.cover,
    required this.name,
    this.subtitle,
    this.meta,
    this.actions = const [],
  });

  /// Builds the cover at the given size; null lays out the text only.
  final Widget Function(double size)? cover;
  final String name;

  /// A line under the name (e.g. the artist link).
  final Widget? subtitle;
  final String? meta;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= CcDims.wideBreakpoint;
    final stacked = !wide && (width / scale < 300 || width < 360);
    final coverSize = wide ? 200.0 : 128.0;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          key: const ValueKey('collection-name'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: wide ? theme.displaySmall : theme.headlineSmall,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          DefaultTextStyle.merge(
            style: theme.bodyLarge?.copyWith(color: cc.textMuted),
            child: subtitle!,
          ),
        ],
        if (meta != null) ...[
          const SizedBox(height: 4),
          Text(meta!, style: theme.bodyMedium?.copyWith(color: cc.textMuted)),
        ],
      ],
    );
    final coverBox = cover == null
        ? null
        : KeyedSubtree(
            key: const ValueKey('collection-cover'),
            child: cover!(coverSize),
          );
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 960 : double.infinity),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CcDims.margin,
            8,
            CcDims.margin,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (coverBox == null)
                info
              else if (stacked) ...[
                coverBox,
                const SizedBox(height: 16),
                info,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    coverBox,
                    SizedBox(width: wide ? 24 : 16),
                    Expanded(child: info),
                  ],
                ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// «Disco 2» style label between groups of rows.
class DiscHeader extends StatelessWidget {
  const DiscHeader(this.disc, {super.key});

  final int disc;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(CcDims.margin, 16, CcDims.margin, 4),
    child: Text(
      context.l10n.discN(disc),
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: context.cc.textMuted),
    ),
  );
}
