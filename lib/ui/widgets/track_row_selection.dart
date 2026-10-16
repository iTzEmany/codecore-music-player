import 'package:flutter/material.dart';

import '../theme/tokens.dart';

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
class SelectionBox extends StatelessWidget {
  const SelectionBox({super.key, required this.selected, required this.size});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final box = size < 32 ? 22.0 : 26.0;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: AnimatedContainer(
          duration: ccDuration(context, CcMotion.press),
          width: box,
          height: box,
          decoration: BoxDecoration(
            color: selected ? cc.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(CcDims.rList + 2),
            border: Border.all(
              color: selected ? cc.accent : cc.textMuted,
              width: 2,
            ),
          ),
          child: selected
              ? Icon(Icons.check_rounded, size: box - 6, color: cc.onAccent)
              : null,
        ),
      ),
    );
  }
}
