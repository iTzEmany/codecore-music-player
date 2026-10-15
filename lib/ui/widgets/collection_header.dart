import 'package:flutter/material.dart';

import '../../l10n/l10n_ext.dart';
import '../theme/tokens.dart';
import 'cover_backdrop.dart';
import 'play_buttons.dart';

/// Page of one collection (album, artist, playlist, favourites): a tinted
/// backdrop, a pinned bar whose title appears while scrolling, the big cover
/// with name and meta, then the actions row and the page's own slivers.
class CollectionScaffold extends StatefulWidget {
  const CollectionScaffold({
    super.key,
    required this.title,
    required this.name,
    required this.cover,
    required this.slivers,
    this.coverKey,
    this.subtitle,
    this.meta,
    this.menu,
    this.onPlay,
    this.onShuffle,
    this.barActions = const [],
  });

  /// Shown in the pinned bar once the big name has scrolled away.
  final String title;
  final String name;

  /// Builds the cover at the given size.
  final Widget Function(double size) cover;
  final List<Widget> slivers;

  /// Drives the backdrop tint.
  final String? coverKey;

  /// A line under the name (e.g. the artist link).
  final Widget? subtitle;
  final String? meta;
  final Widget? menu;
  final VoidCallback? onPlay, onShuffle;
  final List<Widget> barActions;

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
    final theme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= CcDims.wideBreakpoint;
    final coverSize = wide ? 232.0 : (width * 0.6).clamp(120.0, 280.0);
    final nameStyle = widget.name.length > 40
        ? theme.displaySmall?.copyWith(fontSize: 24)
        : theme.displaySmall;
    final nameText = Text(
      widget.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: nameStyle,
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        nameText,
        if (widget.subtitle != null) ...[
          const SizedBox(height: 6),
          widget.subtitle!,
        ],
        if (widget.meta != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.meta!,
            style: theme.bodyMedium?.copyWith(color: cc.textMuted),
          ),
        ],
      ],
    );
    final actions = Row(
      children: [
        ?widget.menu,
        const Spacer(),
        if (widget.onShuffle != null)
          ShuffleButton(onPressed: widget.onShuffle),
        const SizedBox(width: 8),
        PlayCircleButton(size: 56, onPressed: widget.onPlay),
      ],
    );
    return Scaffold(
      backgroundColor: cc.bg,
      body: CoverBackdrop(
        coverKey: widget.coverKey,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _showTitle ? cc.surface1 : Colors.transparent,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  CcDims.margin,
                  8,
                  CcDims.margin,
                  12,
                ),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          widget.cover(coverSize),
                          const SizedBox(width: 24),
                          Expanded(child: info),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: widget.cover(coverSize)),
                          const SizedBox(height: 16),
                          info,
                        ],
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
                child: actions,
              ),
            ),
            ...widget.slivers,
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
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
