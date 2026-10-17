import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../theme/tokens.dart';

/// The guide to the rule language, from the «?» next to the search box.
Future<void> showRulesHelp(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => const _RulesHelp(),
);

class _RulesHelp extends StatelessWidget {
  const _RulesHelp();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final rows = [
      l.ruleHelpArtist,
      l.ruleHelpYear,
      l.ruleHelpDuration,
      l.ruleHelpAdded,
      l.ruleHelpNot,
      l.ruleHelpOr,
      l.ruleHelpFlags,
      l.ruleHelpOthers,
    ];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            CcDims.margin,
            0,
            CcDims.margin,
            CcDims.margin,
          ),
          children: [
            Text(l.ruleHelpTitle, style: theme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l.ruleHelpIntro,
              style: theme.bodyMedium?.copyWith(color: cc.textMuted),
            ),
            const SizedBox(height: 12),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(r, style: theme.bodyLarge),
              ),
            const SizedBox(height: 8),
            Text(
              l.ruleHelpSmart,
              style: theme.bodyMedium?.copyWith(color: cc.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
