import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// Square sample of a theme: its background, an accent dot and its name.
class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({
    super.key,
    required this.label,
    required this.colors,
    required this.selected,
    required this.onTap,
    this.mark,
  });

  final String label;
  final CcColors colors;
  final bool selected;
  final VoidCallback onTap;

  /// An icon in place of the accent dot («new theme»).
  final IconData? mark;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(CcDims.rCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(CcDims.rCard),
                  border: Border.all(
                    color: selected ? cc.accent : cc.surface3,
                    width: selected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: mark != null
                    ? Icon(mark, color: colors.accent)
                    : Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: selected ? cc.text : cc.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
