import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import '../theme/tokens.dart';
import 'format_utils.dart';

bool isHiRes(Track t) =>
    (t.bitDepth ?? 0) >= 24 || (t.sampleRateHz ?? 0) > 48000;

/// Small lilac tag: «Hi-Res · FLAC • 24 bit / 96 kHz» or just the format line.
class QualityTag extends StatelessWidget {
  const QualityTag(this.track, {super.key});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final text = isHiRes(track)
        ? 'Hi-Res · ${qualityLabel(track)}'
        : qualityLabel(track);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cc.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(CcDims.rList),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: cc.accentSoft)),
      ),
    );
  }
}
