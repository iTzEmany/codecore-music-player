import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A round tap target whose keyboard focus draws an accent ring OVER the
/// (opaque) cover, where an InkWell's own highlight would be hidden.
class FocusRingButton extends StatefulWidget {
  const FocusRingButton({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<FocusRingButton> createState() => _FocusRingButtonState();
}

class _FocusRingButtonState extends State<FocusRingButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => InkWell(
    customBorder: const CircleBorder(),
    onTap: widget.onTap,
    onFocusChange: (f) => setState(() => _focused = f),
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: _focused && FocusManager.instance.highlightMode == FocusHighlightMode.traditional
            ? Border.all(color: context.cc.accent, width: 2)
            : null,
      ),
      child: widget.child,
    ),
  );
}
