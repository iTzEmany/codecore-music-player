import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/import_providers.dart';
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
    final original =
        ref.watch(settingsProvider.select((s) => s.downloadOriginal));
    final rate =
        ref.watch(settingsProvider.select((s) => s.downloadRateLimitKBps));
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
        SwitchListTile(
          secondary: const Icon(Icons.high_quality_outlined),
          title: Text(l.downloadOriginal),
          subtitle: Text(l.downloadOriginalHint),
          value: original,
          onChanged: (v) => ref
              .read(settingsProvider.notifier)
              .update((c) => c.copyWith(downloadOriginal: v)),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.cloud_outlined),
          title: Text(l.importSoundCloud),
          subtitle: Text(l.importSoundCloudHint),
          value: ref.watch(settingsProvider.select((s) => s.importSoundCloud)),
          onChanged: (v) => ref
              .read(settingsProvider.notifier)
              .update((c) => c.copyWith(importSoundCloud: v)),
        ),
        const _SearchCacheTile(),
        ListTile(
          leading: const Icon(Icons.speed),
          title: Text(l.downloadRateLimit),
          trailing: DropdownButton<int>(
            value: _rateChoices.contains(rate) ? rate : 0,
            underline: const SizedBox.shrink(),
            items: [
              for (final v in _rateChoices)
                DropdownMenuItem(value: v, child: Text(_rateLabel(l, v))),
            ],
            onChanged: (v) => v == null
                ? null
                : ref
                    .read(settingsProvider.notifier)
                    .update((c) => c.copyWith(downloadRateLimitKBps: v)),
          ),
        ),
      ],
    );
  }
}

const _rateChoices = [0, 500, 1000, 2000];

String _rateLabel(AppLocalizations l, int kb) => kb == 0
    ? l.downloadRateNone
    : kb >= 1000
        ? l.downloadRateMb(kb ~/ 1000)
        : l.downloadRateKb(kb);

class _SearchCacheTile extends ConsumerWidget {
  const _SearchCacheTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final n = ref.watch(searchCacheCountProvider).value ?? 0;
    return ListTile(
      leading: const Icon(Icons.manage_search),
      title: Text(l.searchCacheClear),
      subtitle: Text(l.searchCacheCount(n)),
      enabled: n > 0,
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        await ref.read(searchCacheProvider).clear();
        ref.invalidate(searchCacheCountProvider);
        messenger.showSnackBar(SnackBar(content: Text(l.searchCacheCleared)));
      },
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
