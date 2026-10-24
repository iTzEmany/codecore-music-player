import 'package:flutter/material.dart';

import '../../core/platform.dart';
import '../../core/text_utils.dart';
import '../theme/tokens.dart';

/// «A»–«Z» for letters (accents folded), «#» for everything else.
String leadingLetter(String? text) {
  final t = (text ?? '').trim();
  if (t.isEmpty) return '#';
  final folded = normalize(t);
  if (folded.isEmpty) return '#';
  final c = String.fromCharCode(folded.runes.first).toUpperCase();
  return RegExp(r'^[A-Z]$').hasMatch(c) ? c : '#';
}

/// A draggable strip at the right edge of a fixed-extent list: dragging it
/// jumps to the item whose initial sits under the finger and shows the
/// letter in a bubble.
class AlphaScroller extends StatefulWidget {
  const AlphaScroller({
    super.key,
    required this.controller,
    required this.letters,
    required this.itemExtent,
    required this.child,
  });

  final ScrollController controller;

  /// One letter per list item, in list order.
  final List<String> letters;
  final double itemExtent;
  final Widget child;

  @override
  State<AlphaScroller> createState() => _AlphaScrollerState();
}

class _AlphaScrollerState extends State<AlphaScroller> {
  String? _bubble;

  void _jump(double dy, double height) {
    final n = widget.letters.length;
    if (n == 0 || height <= 0) return;
    final f = (dy / height).clamp(0.0, 1.0);
    final index = (f * (n - 1)).round();
    final c = widget.controller;
    if (c.hasClients) {
      c.jumpTo(
        (index * widget.itemExtent).clamp(0.0, c.position.maxScrollExtent),
      );
    }
    setState(() => _bubble = widget.letters[index]);
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: isDesktop ? 28 : 48,
          child: LayoutBuilder(
            builder: (_, c) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragStart: (d) =>
                  _jump(d.localPosition.dy, c.maxHeight),
              onVerticalDragUpdate: (d) =>
                  _jump(d.localPosition.dy, c.maxHeight),
              onVerticalDragEnd: (_) => setState(() => _bubble = null),
              onVerticalDragCancel: () => setState(() => _bubble = null),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        if (_bubble != null)
          Positioned(
            right: 40,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cc.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _bubble!,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: cc.onAccent),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
