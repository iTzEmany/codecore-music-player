import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/jam_providers.dart';
import '../../providers/player_providers.dart';
import '../theme/tokens.dart';
import '../widgets/mini_player.dart';
import '../widgets/motion.dart';

class BottomBarItem {
  const BottomBarItem(this.icon, this.selectedIcon, this.label);

  final IconData icon, selectedIcon;
  final String label;
}

const _iconSize = 24.0;
const _tabTop = 8.0; // the icon sits at a fixed height, whatever the text scale
const _dotSize = 6.0;
const _dotLift = 10.0;

/// One block at the bottom: the mini-player (when something plays) above the
/// always-labelled tabs, with a dot on the active tab's icon.
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
        showPlayer && (track != null || ref.watch(jamProvider).active);
    const m = CcDims.dockMargin;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        m,
        m,
        m,
        m + MediaQuery.paddingOf(context).bottom,
      ),
      // Material (not a coloured Container) so the ink of the taps shows.
      child: Material(
        color: cc.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CcDims.dockRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPlayer) const MiniPlayer(),
            _Tabs(items: items, selected: selected, onSelect: onSelect),
          ],
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
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: i == selected ? cc.text : cc.textMuted,
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
  late int _from = widget.index;

  @override
  void didUpdateWidget(_TabDot old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _from = old.index;
    _c.duration = ccDuration(context, Motion.dot);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Centre of the icon's top-right corner in tab [i].
  double _x(int i) => (i + 0.5) * widget.tabWidth + _iconSize / 2;

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
                final t = Curves.easeInOut.transform(_c.value);
                final x = _x(_from) + (_x(widget.index) - _x(_from)) * t;
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
