import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/youtube_providers.dart';
import '../../../services/online/download_queue.dart';
import '../../../services/online/youtube_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_utils.dart';

String ytErrorText(BuildContext context, YtErrorKind k) {
  final l = context.l10n;
  return switch (k) {
    YtErrorKind.unavailable => l.ytErrUnavailable,
    YtErrorKind.network => l.ytErrNetwork,
    YtErrorKind.changed => l.ytErrChanged,
    YtErrorKind.toolMissing => l.ytErrToolMissing,
  };
}

/// YouTube results for [query]. The search runs only when [submitted]
/// changes (Enter / the arrow / «Cerca su YouTube»), never while typing.
class YoutubeResults extends ConsumerStatefulWidget {
  const YoutubeResults({
    super.key,
    required this.query,
    required this.submitted,
  });

  final String query;
  final int submitted;

  @override
  ConsumerState<YoutubeResults> createState() => _YoutubeResultsState();
}

class _YoutubeResultsState extends ConsumerState<YoutubeResults> {
  List<YtResult> _results = const [];
  bool _searching = false;
  bool _searched = false;
  YtErrorKind? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.submitted > 0) _search();
  }

  @override
  void didUpdateWidget(YoutubeResults old) {
    super.didUpdateWidget(old);
    if (widget.submitted != old.submitted) _search();
  }

  Future<void> _search() async {
    final q = widget.query.trim();
    if (q.isEmpty) return;
    final id = ++_requestId;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final res = await ref.read(youtubeServiceProvider).search(q);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = res;
        _searched = true;
      });
    } on YtException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() => _error = e.kind);
    } finally {
      if (mounted && id == _requestId) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final seen = ref.watch(settingsProvider.select((s) => s.ytNoticeSeen));
    final downloads = ref.watch(downloadsProvider);
    final index = ref.watch(downloadIndexProvider).value;
    final active = downloads
        .where((d) =>
            d.status == DownloadStatus.queued ||
            d.status == DownloadStatus.downloading)
        .length;
    final theme = Theme.of(context).textTheme;
    return Column(children: [
      if (!seen)
        Padding(
          padding: const EdgeInsets.fromLTRB(
              CcDims.margin, 4, CcDims.margin, 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cc.surface1,
              borderRadius: BorderRadius.circular(CcDims.rCard),
            ),
            child: Row(children: [
              Expanded(child: Text(l.ytLegal, style: theme.bodyMedium)),
              TextButton(
                onPressed: () => ref
                    .read(settingsProvider.notifier)
                    .update((s) => s.copyWith(ytNoticeSeen: true)),
                child: Text(l.gotIt),
              ),
            ]),
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
        child: Row(children: [
          if (seen)
            IconButton(
              tooltip: l.ytInfoTooltip,
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  content: Text(l.ytLegal),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l.close),
                    ),
                  ],
                ),
              ),
            ),
          const Spacer(),
          if (downloads.isNotEmpty)
            ActionChip(
              avatar: const Icon(Icons.download_rounded, size: 18),
              label: Text(l.downloadsChip(active)),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const DownloadsSheet(),
              ),
            ),
        ]),
      ),
      if (_searching) const LinearProgressIndicator(),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(ytErrorText(context, _error!),
              style: TextStyle(color: cc.error)),
        ),
      Expanded(
        child: _results.isEmpty
            ? EmptyState(
                icon: Icons.smart_display,
                message: _searched ? l.ytNoResults : l.ytSearchPrompt)
            : ListView.builder(
                itemExtent: 72,
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final r = _results[i];
                  final inLibrary = index?.contains(r.id) ?? false;
                  final item = downloads
                      .where((d) => d.result.id == r.id)
                      .lastOrNull;
                  return _ResultRow(
                    result: r,
                    inLibrary: inLibrary,
                    item: item,
                    onDownload: () =>
                        ref.read(downloadsProvider.notifier).add(r),
                  );
                },
              ),
      ),
    ]);
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.result,
    required this.inLibrary,
    required this.item,
    required this.onDownload,
  });

  final YtResult result;
  final bool inLibrary;
  final DownloadItem? item;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final meta = [
      result.channel,
      if (result.duration != null)
        formatDuration(result.duration!.inMilliseconds),
    ].join(' · ');
    final st = item?.status;
    final Widget trailing;
    if (st == DownloadStatus.queued || st == DownloadStatus.downloading) {
      trailing = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          value: st == DownloadStatus.downloading ? item!.progress : null,
        ),
      );
    } else if (st == DownloadStatus.done || inLibrary) {
      trailing = Icon(Icons.check_circle_rounded, color: cc.accentSoft);
    } else if (st == DownloadStatus.failed) {
      trailing = IconButton(
        tooltip: l.retry,
        icon: Icon(Icons.warning_amber_rounded, color: cc.error),
        onPressed: onDownload,
      );
    } else {
      trailing = IconButton(
        tooltip: l.ytDownload,
        icon: const Icon(Icons.download_rounded),
        onPressed: onDownload,
      );
    }
    return SizedBox(
      height: 72,
      child: Row(children: [
        const SizedBox(width: CcDims.margin),
        ClipRRect(
          borderRadius: BorderRadius.circular(CcDims.rList),
          child: SizedBox(
            width: 80,
            height: 45,
            child: result.thumbnailUrl == null
                ? ColoredBox(
                    color: cc.surface3,
                    child: Icon(Icons.music_video, color: cc.textMuted))
                : Image.network(
                    result.thumbnailUrl!,
                    cacheWidth: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                        color: cc.surface3,
                        child: Icon(Icons.music_video, color: cc.textMuted)),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyLarge),
              Text(meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium),
              if (inLibrary)
                Text(l.ytAlreadyInLibrary,
                    style: theme.labelSmall?.copyWith(color: cc.accentSoft)),
            ],
          ),
        ),
        trailing,
        const SizedBox(width: 8),
      ]),
    );
  }
}

/// The running and finished downloads (replaced by the Activity centre).
class DownloadsSheet extends ConsumerWidget {
  const DownloadsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(downloadsProvider);
    final n = ref.read(downloadsProvider.notifier);
    String status(DownloadItem d) => switch (d.status) {
          DownloadStatus.queued => l.ytQueued,
          DownloadStatus.downloading => l.ytDownloading,
          DownloadStatus.done => l.ytDone,
          DownloadStatus.failed => d.error == null
              ? l.ytFailed
              : ytErrorText(context, d.error!),
          DownloadStatus.cancelled => l.ytCancelled,
        };
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: n.clearFinished, child: Text(l.ytClearCompleted)),
          ),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final d in items)
                ListTile(
                  title: Text(d.result.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: d.status == DownloadStatus.downloading
                      ? LinearProgressIndicator(value: d.progress)
                      : Text(status(d)),
                  trailing: (d.status == DownloadStatus.queued ||
                          d.status == DownloadStatus.downloading)
                      ? IconButton(
                          tooltip: l.ytCancel,
                          icon: const Icon(Icons.close),
                          onPressed: () => n.cancel(d.id))
                      : null,
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
