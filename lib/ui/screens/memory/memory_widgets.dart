import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../theme/tokens.dart';
import '../../widgets/format_utils.dart';

/// Width (at normal text size) of the size label column of a [WeightRow].
const sizeColumnWidth = 76.0;

/// A row of a «Memoria» list: name, what it holds, how much space it takes,
/// and a thin bar of its share ([fraction] 0–1, null = no bar).
class WeightRow extends StatelessWidget {
  const WeightRow({
    super.key,
    required this.title,
    required this.bytes,
    this.subtitle,
    this.leading,
    this.fraction,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final int bytes;
  final Widget? leading;
  final double? fraction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final f = fraction;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CcDims.margin,
          vertical: 8,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyLarge,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium?.copyWith(color: cc.textMuted),
                    ),
                  if (f != null) ...[
                    const SizedBox(height: 6),
                    ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: f.clamp(0.0, 1.0),
                          minHeight: 4,
                          color: cc.accent,
                          backgroundColor: cc.surface3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // A fixed column, so every bar in the list has the same track.
            SizedBox(
              width: MediaQuery.textScalerOf(context).scale(sizeColumnWidth),
              child: Text(
                formatBytes(bytes),
                maxLines: 1,
                textAlign: TextAlign.end,
                style: theme.titleSmall?.copyWith(color: cc.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Share of [part] in [whole] for a bar; 0 when there is no whole.
double shareOf(int part, int whole) => whole <= 0 ? 0 : part / whole;

/// The card at the top: a surface with rounded corners holding [child].
class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(CcDims.margin, 12, CcDims.margin, 0),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.cc.surface1,
        borderRadius: BorderRadius.circular(CcDims.rCard),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

/// «musica · altro · libero» as one bar with a legend.
class DeviceBar extends StatelessWidget {
  const DeviceBar({
    super.key,
    required this.musicBytes,
    required this.otherBytes,
    required this.freeBytes,
  });

  final int musicBytes, otherBytes, freeBytes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final total = musicBytes + otherBytes + freeBytes;
    int flex(int v) => v <= 0 ? 0 : (v * 1000 / total).ceil();
    final parts = [
      (l.memoryMusicLabel, musicBytes, cc.accent),
      (l.memoryOtherLabel, otherBytes, cc.textFaint),
      (l.memoryFreeLabel, freeBytes, cc.surface3),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: [
            for (final (name, bytes, _) in parts) '$name ${formatBytes(bytes)}',
          ].join(', '),
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (final (_, bytes, color) in parts)
                      if (flex(bytes) > 0)
                        Expanded(
                          flex: flex(bytes),
                          child: ColoredBox(color: color),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            for (final (name, bytes, color) in parts)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$name ${formatBytes(bytes)}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: cc.textMuted),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
