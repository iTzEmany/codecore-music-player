import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/youtube_providers.dart';
import '../../../providers/yt_dlp_update_providers.dart';
import '../../widgets/yt_dlp_update_button.dart';

/// Rows of the «Download» group in the settings.
class DownloadSettingsTiles extends ConsumerWidget {
  const DownloadSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(children: [_YtDlpTile()]);
  }
}

class _YtDlpTile extends ConsumerWidget {
  const _YtDlpTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(ytDlpStatusProvider);
    final update = ref.watch(ytDlpUpdateProvider);
    final version = status.value?.version;
    final message = ytDlpUpdateMessage(l, update) ??
        (status.value?.outdated ?? false ? l.ytDlpTooOld : null);
    return ListTile(
      leading: const Icon(Icons.download_for_offline_outlined),
      title: Text(
        status.isLoading
            ? 'yt-dlp …'
            : version == null
                ? l.ytDlpUnknownVersion
                : l.ytDlpVersion(version),
      ),
      subtitle: message == null ? null : Text(message),
      // Android updates the embedded yt-dlp by itself on first use.
      trailing: isDesktop ? const YtDlpUpdateButton() : null,
    );
  }
}
