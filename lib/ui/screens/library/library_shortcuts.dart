import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/motion.dart';

class LibraryShortcut {
  const LibraryShortcut({
    required this.label,
    this.count,
    required this.onTap,
    this.keepWhenZero = false,
  });

  final String label;
  final int? count;
  final VoidCallback onTap;
  final bool keepWhenZero;
}

/// The Libreria shortcuts as wrapping pills; empty ones are hidden.
class LibraryShortcuts extends StatelessWidget {
  const LibraryShortcuts({super.key, required this.items});

  final List<LibraryShortcut> items;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    const radius = BorderRadius.all(Radius.circular(14));
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 8, CcDims.margin, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in items)
            if (s.count != 0 || s.keepWhenZero)
              Semantics(
                button: true,
                child: PressScale(
                  child: Material(
                    color: cc.surface1,
                    borderRadius: radius,
                    child: InkWell(
                      borderRadius: radius,
                      onTap: s.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                s.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.labelLarge,
                              ),
                            ),
                            if (s.count != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${s.count}',
                                style: theme.bodyMedium?.copyWith(
                                  color: cc.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
