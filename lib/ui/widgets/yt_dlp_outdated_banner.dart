import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/youtube_providers.dart';
import '../theme/tokens.dart';

/// «yt-dlp è troppo vecchio»: shown on desktop when `yt-dlp --version` is
/// older than the minimum the downloads need. Nothing otherwise.
class YtDlpOutdatedBanner extends ConsumerWidget {
  const YtDlpOutdatedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDesktop) return const SizedBox.shrink();
    final status = ref.watch(ytDlpStatusProvider).value;
    if (status == null || !status.outdated) return const SizedBox.shrink();
    final cc = context.cc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          CcDims.margin, 4, CcDims.margin, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cc.surface1,
          borderRadius: BorderRadius.circular(CcDims.rCard),
          border: Border.all(color: cc.error),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: cc.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.ytDlpOutdatedBanner(status.version ?? ''),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
