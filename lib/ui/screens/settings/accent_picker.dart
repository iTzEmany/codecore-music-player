import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

String accentLabel(AppLocalizations l, CcAccent a) => switch (a) {
  CcAccent.viola => l.accentViola,
  CcAccent.blu => l.accentBlu,
  CcAccent.acqua => l.accentAcqua,
  CcAccent.verde => l.accentVerde,
  CcAccent.ambra => l.accentAmbra,
  CcAccent.arancio => l.accentArancio,
  CcAccent.rosa => l.accentRosa,
  CcAccent.rosso => l.accentRosso,
};

/// A row of round samples, one per accent colour. They are shown in the colour
/// they would have on the theme in use ([theme]).
class AccentPicker extends StatelessWidget {
  const AccentPicker({
    super.key,
    required this.theme,
    required this.selected,
    required this.onSelected,
  });

  final AppThemeId theme;
  final CcAccent selected;
  final ValueChanged<CcAccent> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final a in CcAccent.values)
          Semantics(
            button: true,
            selected: a == selected,
            label: accentLabel(l, a),
            child: Tooltip(
              message: accentLabel(l, a),
              child: InkResponse(
                radius: 26,
                onTap: () => onSelected(a),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: buildPalette(theme, a).accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: a == selected ? cc.text : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: a == selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 22,
                          color: buildPalette(theme, a).onAccent,
                        )
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
