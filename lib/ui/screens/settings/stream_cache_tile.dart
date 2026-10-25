import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/stream_providers.dart';
import '../../../services/stream/stream_key.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/show_msg.dart';

const _minMb = 256, _maxMb = 8192, _stepMb = 256;

/// Slider for the streaming cache size, its used space and «Svuota».
class StreamCacheTile extends ConsumerStatefulWidget {
  const StreamCacheTile({super.key});

  @override
  ConsumerState<StreamCacheTile> createState() => _StreamCacheTileState();
}

class _StreamCacheTileState extends ConsumerState<StreamCacheTile> {
  double? _drag;
  bool _busy = false;

  Future<void> _clear() async {
    final l = context.l10n;
    final current = ref.read(currentTrackProvider).value;
    final currentKey = current == null ? null : keyOfStreamPath(current.path);
    setState(() => _busy = true);
    try {
      await clearStreamCache(
        ref.read(streamCacheProvider),
        ref.read(trackRepositoryProvider),
        keep: {?currentKey, ...ref.read(streamPreparerProvider).queuedKeys},
      );
      ref.invalidate(streamCacheUsedProvider);
      if (mounted) showMsg(context, l.streamCacheCleared);
    } catch (e, st) {
      AppLog.e('stream cache: clear failed', e, st);
      if (mounted) showMsg(context, l.streamCacheClearFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = l.localeName;
    final mb = ref.watch(settingsProvider.select((s) => s.streamCacheMb));
    final used = ref.watch(streamCacheUsedProvider).value ?? 0;
    final shown = (_drag ?? mb.toDouble());
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: Text(l.streamCacheTitle),
          subtitle: Text(l.streamCacheUsage(
            formatBytes(used, locale),
            formatBytes(shown.round() * 1024 * 1024, locale),
          )),
          trailing: TextButton(onPressed: _busy ? null : _clear, child: Text(l.streamCacheClear)),
        ),
        Slider(
          value: shown,
          min: _minMb.toDouble(),
          max: _maxMb.toDouble(),
          divisions: (_maxMb - _minMb) ~/ _stepMb,
          label: formatBytes(shown.round() * 1024 * 1024, locale),
          onChanged: (v) => setState(() => _drag = v),
          onChangeEnd: (v) {
            setState(() => _drag = null);
            ref.read(settingsProvider.notifier).update((c) => c.copyWith(streamCacheMb: v.round()));
          },
        ),
      ],
    );
  }
}
