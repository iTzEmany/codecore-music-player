import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/jam_providers.dart';
import '../../providers/nav_providers.dart';
import '../../providers/player_providers.dart';
import '../../providers/ui_providers.dart';
import '../theme/tokens.dart';
import '../widgets/mini_player.dart';

class BottomBarItem {
  const BottomBarItem(this.icon, this.selectedIcon, this.label);

  final IconData icon, selectedIcon;
  final String label;
}

const _iconSize = 24.0;
const _tabTop = 8.0; // the icon sits at a fixed height, whatever the text scale
const _dotSize = 6.0;
// Small enough that the apex stays inside the dock's clip when the tabs are
// its top edge (no track playing).
const _dotLift = 4.0;

// The «Cerca» tab's centre, horizontally, in the dock (second of four).
const _searchTabAlign = Alignment(-0.33, 0);

/// One block at the bottom: the mini-player (when something plays) above the
/// always-labelled tabs, with a dot on the active tab's icon. While the Search
/// field is open it is replaced by the field alone.
class ShellDock extends ConsumerWidget {
  const ShellDock({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    this.showPlayer = true,
  });

  final List<BottomBarItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool showPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cc = context.cc;
    final track =
        ref.watch(liveCurrentTrackProvider).value ??
        ref.watch(currentTrackProvider).value;
    final hasPlayer =
        showPlayer &&
        (track != null || ref.watch(jamProvider.select((j) => j.active)));
    final field =
        ref.watch(searchBarProvider) && selected == NavTab.search.index;
    const m = CcDims.dockMargin;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        m,
        m,
        m,
        // The Scaffold does not lift its bottom bar: the field clears the
        // keyboard by itself.
        CcDims.dockBottom +
            MediaQuery.paddingOf(context).bottom +
            (field ? MediaQuery.viewInsetsOf(context).bottom : 0),
      ),
      // Material (not a coloured Container) so the ink of the taps shows.
      child: Material(
        color: cc.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CcDims.dockRadius),
        ),
        clipBehavior: Clip.antiAlias,
        // Opacity and a horizontal scale from the «Cerca» tab; the dock takes
        // the new height at once, so no size is animated.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CcDims.gap8,
            CcDims.gap8,
            CcDims.gap8,
            6,
          ),
          child: AnimatedSwitcher(
            duration: ccDuration(context, CcMotion.page),
            switchInCurve: CcMotion.curveIn,
            switchOutCurve: CcMotion.curveOut,
            layoutBuilder: (current, previous) => Stack(
              children: [
                for (final p in previous)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(child: p),
                  ),
                ?current,
              ],
            ),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: AnimatedBuilder(
                animation: a,
                builder: (_, child) => Transform.scale(
                  scaleX: 0.5 + 0.5 * a.value,
                  alignment: _searchTabAlign,
                  child: child,
                ),
                child: child,
              ),
            ),
            child: field
                ? Stack(
                    key: const ValueKey('dock-field'),
                    alignment: Alignment.center,
                    children: [
                      // Hidden tabs hold the dock's height: the page above
                      // keeps its size and its scroll offset.
                      // Sized only: no taps, focus or TalkBack on them.
                      Visibility(
                        visible: false,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: _Tabs(
                          items: items,
                          selected: selected,
                          onSelect: onSelect,
                        ),
                      ),
                      const _SearchField(),
                    ],
                  )
                : Column(
                    key: const ValueKey('dock-tabs'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasPlayer) ...[
                        const MiniPlayer(),
                        // 1 dp rule between the player and the tabs.
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: CcDims.gap8,
                          endIndent: CcDims.gap8,
                          color: cc.surface3,
                        ),
                        const SizedBox(height: CcDims.gap4),
                      ],
                      _Tabs(
                        items: items,
                        selected: selected,
                        onSelect: onSelect,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// The dock while searching: the shared Search field and a ✕.
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  @override
  void initState() {
    super.initState();
    // autofocus loses to a focus the tapped tab may have left in the scope.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => mounted ? ref.read(searchFocusProvider).requestFocus() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final online = ref.watch(searchOnlineProvider);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: CcDims.bottomBarHeight),
      // heightFactor: the bottom bar slot is as tall as the screen.
      child: Center(
        heightFactor: 1,
        child: TextField(
          controller: ref.watch(searchControllerProvider),
          focusNode: ref.watch(searchFocusProvider),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => ref.read(searchSubmitProvider.notifier).submit(),
          decoration: InputDecoration(
            hintText: online ? l.ytHint : l.searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: l.closeSearch,
              icon: const Icon(Icons.close_rounded),
              onPressed: ref.read(searchBarProvider.notifier).dismiss,
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<BottomBarItem> items;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    label: items[i].label,
                    child: InkWell(
                      onTap: () => onSelect(i),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: CcDims.bottomBarHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: _tabTop,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                i == selected
                                    ? items[i].selectedIcon
                                    : items[i].icon,
                                size: _iconSize,
                                color: i == selected ? cc.text : cc.textMuted,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                items[i].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: i == selected
                                          ? cc.text
                                          : cc.textMuted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _TabDot(
            index: selected,
            tabWidth: box.maxWidth / items.length,
            color: cc.accent,
          ),
        ],
      ),
    );
  }
}

/// The accent dot at the top right of the active icon. It hops to the new tab
/// along a small arc; with «Riduci animazioni» the duration is zero, so it
/// just jumps.
class _TabDot extends StatefulWidget {
  const _TabDot({
    required this.index,
    required this.tabWidth,
    required this.color,
  });

  final int index;
  final double tabWidth;
  final Color color;

  @override
  State<_TabDot> createState() => _TabDotState();
}

class _TabDotState extends State<_TabDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: 1,
  );
  late double _fromX = _x(widget.index);

  @override
  void didUpdateWidget(_TabDot old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    // Start from where the dot is now, so a quick second tap doesn't jump back.
    _fromX = _currentX(old.index, old.tabWidth);
    _c.duration = ccDuration(context, CcMotion.page);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Centre of the icon's top-right corner in tab [i].
  double _x(int i, [double? tabWidth]) =>
      (i + 0.5) * (tabWidth ?? widget.tabWidth) + _iconSize / 2;

  // Where the dot is, heading for tab [to].
  double _currentX(int to, [double? tabWidth]) =>
      _fromX +
      (_x(to, tabWidth) - _fromX) * CcMotion.curveIn.transform(_c.value);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final t = CcMotion.curveIn.transform(_c.value);
                final x = _currentX(widget.index);
                final y = _tabTop - math.sin(math.pi * t) * _dotLift;
                return Transform.translate(
                  offset: Offset(x - _dotSize / 2, y - _dotSize / 2),
                  child: child,
                );
              },
              child: Container(
                key: const ValueKey('tab-dot'),
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
