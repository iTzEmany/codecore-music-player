import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Swipe-to-remove backdrop: tinted with the error colour, with a bin icon.
class DismissBackground extends StatelessWidget {
  const DismissBackground({super.key, this.alignEnd = false});

  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return Container(
      color: cc.error.withValues(alpha: 0.2),
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
      child: Icon(Icons.delete_outline_rounded, color: cc.error),
    );
  }
}
