import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import 'format_utils.dart';

class QualityBadge extends StatelessWidget {
  const QualityBadge(this.track, {super.key});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(qualityLabel(track),
            style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}
