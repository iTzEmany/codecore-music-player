import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/youtube_providers.dart';
import '../../../services/online/download_queue.dart';
import '../../../services/online/youtube_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_utils.dart';

class YoutubeScreen extends ConsumerStatefulWidget {
  const YoutubeScreen({super.key});

  @override
  ConsumerState<YoutubeScreen> createState() => _YoutubeScreenState();
}

class _YoutubeScreenState extends ConsumerState<YoutubeScreen> {
  final _controller = TextEditingController();
  List<YtResult> _results = const [];
  bool _searching = false;
  bool _searched = false;
  YtErrorKind? _error;
  int _requestId = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searching) return;
    final q = _controller.text;
    if (q.trim().isEmpty) return;
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

  String _errorText(YtErrorKind k) {
    final l = context.l10n;
    return switch (k) {
      YtErrorKind.unavailable => l.ytErrUnavailable,
      YtErrorKind.network => l.ytErrNetwork,
      YtErrorKind.changed => l.ytErrChanged,
      YtErrorKind.toolMissing => l.ytErrToolMissing,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final downloads = ref.watch(downloadsProvider);
    final index = ref.watch(downloadIndexProvider).value;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _controller,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: l.ytHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    icon: const Icon(Icons.arrow_forward), onPressed: _search),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(l.ytLegal, style: Theme.of(context).textTheme.bodySmall),
      ),
      if (_error != null)
        Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_errorText(_error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error))),
      if (downloads.isNotEmpty) _Downloads(items: downloads, errorText: _errorText),
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
                  final queued = downloads.any((d) =>
                      d.result.id == r.id &&
                      (d.status == DownloadStatus.queued ||
                          d.status == DownloadStatus.downloading));
                  return ListTile(
                    leading: r.thumbnailUrl == null
                        ? const Icon(Icons.music_video)
                        : Image.network(r.thumbnailUrl!,
                            width: 80,
                            height: 56,
                            cacheWidth: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.music_video)),
                    title: Text(r.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        '${r.channel}${r.duration == null ? '' : ' • ${formatDuration(r.duration!.inMilliseconds)}'}'
                        '${inLibrary ? ' • ${l.ytAlreadyInLibrary}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      tooltip: l.ytDownload,
                      icon: const Icon(Icons.download),
                      onPressed: queued
                          ? null
                          : () =>
                              ref.read(downloadsProvider.notifier).add(r),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

class _Downloads extends ConsumerWidget {
  const _Downloads({required this.items, required this.errorText});

  final List<DownloadItem> items;
  final String Function(YtErrorKind) errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final n = ref.read(downloadsProvider.notifier);
    String status(DownloadItem d) => switch (d.status) {
          DownloadStatus.queued => l.ytQueued,
          DownloadStatus.downloading => l.ytDownloading,
          DownloadStatus.done => l.ytDone,
          DownloadStatus.failed =>
            d.error == null ? l.ytFailed : errorText(d.error!),
          DownloadStatus.cancelled => l.ytCancelled,
        };
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: Column(children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
              onPressed: n.clearFinished, child: Text(l.ytClearCompleted)),
        ),
        Flexible(
          child: ListView(shrinkWrap: true, children: [
            for (final d in items)
              ListTile(
                dense: true,
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
    );
  }
}
