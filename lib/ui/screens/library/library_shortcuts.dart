import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/motion.dart';

class LibraryShortcut {
  const LibraryShortcut({
    required this.label,
    required this.icon,
    this.count,
    this.meta,
    required this.onTap,
    this.keepWhenZero = false,
  });

  final String label;
  final IconData icon;
  final int? count;

  /// A small second line under the label.
  final String? meta;
  final VoidCallback onTap;
  final bool keepWhenZero;
}

/// The Libreria shortcuts as a grid of equal-width blocks (icon left of the
/// label, like the segmented blocks above); empty ones are hidden.
class LibraryShortcuts extends StatelessWidget {
  const LibraryShortcuts({super.key, required this.items});

  final List<LibraryShortcut> items;

  static const _gap = 8.0;
  static const _radius = BorderRadius.all(Radius.circular(CcDims.rSheet));

  Widget _block(BuildContext context, LibraryShortcut s) {
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: [s.label, if (s.count != null) '${s.count}', if (s.meta != null) s.meta!].join(', '),
      excludeSemantics: true,
      onTap: s.onTap,
      child: PressScale(
        child: Material(
          color: cc.surface1,
          borderRadius: _radius,
          child: InkWell(
            borderRadius: _radius,
            onTap: s.onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: CcDims.gap12, vertical: 10),
                child: Row(
                  children: [
                    Icon(s.icon, size: 22, color: cc.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.labelLarge,
                          ),
                          if (s.meta != null)
                            Text(
                              s.meta!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall?.copyWith(color: cc.textMuted),
                            ),
                        ],
                      ),
                    ),
                    if (s.count != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${s.count}',
                        style: theme.bodyMedium?.copyWith(color: cc.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final s in items)
        if (s.count != 0 || s.keepWhenZero) s,
    ];
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, CcDims.gap8, CcDims.margin, CcDims.gap8),
      child: LayoutBuilder(builder: (context, c) {
        final cols = ((c.maxWidth / scale) ~/ 160).clamp(1, 4);
        return Column(
          children: [
            for (var i = 0; i < visible.length; i += cols) ...[
              if (i > 0) const SizedBox(height: _gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = i; j < i + cols; j++) ...[
                      if (j > i) const SizedBox(width: _gap),
                      Expanded(
                        child: j < visible.length
                            ? _block(context, visible[j])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
