import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/youtube_providers.dart';
import '../../../providers/yt_dlp_update_providers.dart';
import '../../widgets/yt_dlp_update_button.dart';

/// Rows of the «Download» group in the settings.
class DownloadSettingsTiles extends ConsumerWidget {
  const DownloadSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final n = ref.watch(settingsProvider.select((s) => s.downloadParallel));
    return Column(
      children: [
        const _YtDlpTile(),
        ListTile(
          leading: const Icon(Icons.stacked_line_chart),
          title: Text(l.downloadParallel),
          subtitle: Text(l.downloadParallelHint),
          trailing: DropdownButton<int>(
            value: n,
            underline: const SizedBox.shrink(),
            items: [
              for (final v in const [1, 2, 3])
                DropdownMenuItem(value: v, child: Text('$v')),
            ],
            onChanged: (v) => v == null
                ? null
                : ref
                    .read(settingsProvider.notifier)
                    .update((c) => c.copyWith(downloadParallel: v)),
          ),
        ),
      ],
    );
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
