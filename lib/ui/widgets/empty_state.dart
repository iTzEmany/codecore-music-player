import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Quiet empty view: text at the top left, no illustration.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.help,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  /// Kept for callers, not drawn; remove when unused.
  final IconData icon;
  final String message;
  final String? help;
  final String? actionLabel;
  final VoidCallback? onAction, onSecondary;
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(CcDims.margin, 24, CcDims.margin, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: theme.titleSmall),
            if (help != null) ...[
              const SizedBox(height: 4),
              Text(help!, style: theme.bodyMedium),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
            if (secondaryLabel != null)
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ),
      ),
    );
  }
}
