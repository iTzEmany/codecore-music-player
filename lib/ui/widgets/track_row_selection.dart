import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'motion.dart';

/// What a list tells its rows so they can be picked together: the key of its
/// selection (see `selectionProvider`) and the ids as they are shown, which
/// is what a Shift+click range follows.
class RowSelection {
  const RowSelection({required this.listKey, required this.visibleIds});

  final String listKey;
  final List<int> visibleIds;
}

/// The tick box that takes the place of the cover (or number) of a row in
/// selection mode. Same size as what it replaces, so the row keeps its height.
/// A picked row shows its place in the order of the picks ([position], 1-based)
/// instead of a tick when it is known.
class SelectionBox extends StatelessWidget {
  const SelectionBox({
    super.key,
    required this.selected,
    required this.size,
    this.position,
  });

  final bool selected;
  final double size;
  final int? position;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final box = size < 32 ? 22.0 : 26.0;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: // Instant box change: the pop-in below carries the motion (no per-row layout animation).
        Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            color: selected ? cc.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(
              selected && position != null ? box / 2 : CcDims.rList + 2,
            ),
            border: Border.all(
              color: selected ? cc.accent : cc.textMuted,
              width: 2,
            ),
          ),
          child: AnimatedSwitcher(
            duration: ccDuration(context, CcMotion.enter),
            switchInCurve: CcMotion.curveIn,
            transitionBuilder: popIn,
            child: !selected
                ? const SizedBox.shrink()
                : position == null
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('tick'),
                    size: box - 6,
                    color: cc.onAccent,
                  )
                : Padding(
                    key: ValueKey(position),
                    padding: const EdgeInsets.all(2),
                    // FittedBox: a big number or a large system font shrinks
                    // instead of overflowing the circle.
                    child: FittedBox(
                      child: Text(
                        position! > 99 ? '99+' : '$position',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cc.onAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
