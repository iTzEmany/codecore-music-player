import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/sleep_timer_provider.dart';
import '../../../services/audio/play_queue.dart';
import '../../../l10n/l10n_ext.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/favorite_actions.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/quality_badge.dart';
import '../lyrics/lyrics_screen.dart';
import 'queue_sheet.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(liveCurrentTrackProvider).value ??
        ref.watch(currentTrackProvider).value;
    final playing = ref.watch(isPlayingProvider).value ?? false;
    final shuffle = ref.watch(shuffleProvider).value ?? false;
    final repeat = ref.watch(repeatProvider).value ?? PlayRepeat.off;
    final ctrl = ref.read(playerControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.of(context).maybePop()),
        title: Text(context.l10n.nowPlaying),
        actions: [
          const _SleepTimerButton(),
          if (track != null)
            IconButton(
              tooltip: context.l10n.favorite,
              onPressed: () => toggleFavorite(context, ref, track),
              color: track.isFavorite ? scheme.primary : null,
              icon: Icon(track.isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border),
            ),
          IconButton(
            tooltip: context.l10n.lyrics,
            icon: const Icon(Icons.lyrics_outlined),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LyricsScreen())),
          ),
          IconButton(
            tooltip: context.l10n.queue,
            icon: const Icon(Icons.queue_music),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.7,
                maxChildSize: 0.95,
                builder: (_, sc) => QueueSheet(scrollController: sc),
              ),
            ),
          ),
        ],
      ),
      body: track == null
          ? Center(child: Text(context.l10n.nothingPlaying))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (_, c) => Center(
                          child: CoverImage(
                              coverKey: track.coverKey,
                              size: c.biggest.shortestSide.clamp(80, 420),
                              radius: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(track.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(track.artist ?? context.l10n.unknownArtist,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    QualityBadge(track),
                    const _SeekBar(),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconButton(
                        onPressed: ctrl.toggleShuffle,
                        color: shuffle ? scheme.primary : null,
                        icon: const Icon(Icons.shuffle),
                      ),
                      IconButton(
                          iconSize: 36,
                          onPressed: ctrl.previous,
                          icon: const Icon(Icons.skip_previous)),
                      IconButton.filled(
                        iconSize: 44,
                        onPressed: ctrl.togglePlayPause,
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                          iconSize: 36,
                          onPressed: ctrl.next,
                          icon: const Icon(Icons.skip_next)),
                      IconButton(
                        onPressed: ctrl.cycleRepeat,
                        color: repeat == PlayRepeat.off ? null : scheme.primary,
                        icon: Icon(repeat == PlayRepeat.one
                            ? Icons.repeat_one
                            : Icons.repeat),
                      ),
                    ]),
                    if (isDesktop) const _VolumeRow(),
                  ]),
                ),
              ),
            ),
    );
  }
}

class _SeekBar extends ConsumerStatefulWidget {
  const _SeekBar();

  @override
  ConsumerState<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<_SeekBar> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final dur = ref.watch(durationProvider).value ?? Duration.zero;
    final max = dur.inMilliseconds.toDouble();
    final shown = (_dragging ?? pos.inMilliseconds.toDouble())
        .clamp(0.0, max <= 0 ? 1.0 : max);
    return Column(children: [
      Slider(
        value: shown,
        max: max <= 0 ? 1 : max,
        onChanged: max <= 0 ? null : (v) => setState(() => _dragging = v),
        onChangeEnd: (v) {
          setState(() => _dragging = null);
          ref
              .read(playerControllerProvider)
              .seek(Duration(milliseconds: v.round()));
        },
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(formatDuration(shown.round())),
          Text('-${formatDuration((max - shown).round())}'),
        ]),
      ),
    ]);
  }
}

class _VolumeRow extends ConsumerWidget {
  const _VolumeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(volumeProvider);
    final n = ref.read(volumeProvider.notifier);
    return Row(children: [
      IconButton(
        tooltip: context.l10n.mute,
        onPressed: n.toggleMute,
        icon: Icon(v == 0 ? Icons.volume_off : Icons.volume_up),
      ),
      Expanded(child: Slider(value: v, onChanged: n.set)),
    ]);
  }
}

class _SleepTimerButton extends ConsumerWidget {
  const _SleepTimerButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final timer = ref.watch(sleepTimerProvider);
    final notifier = ref.read(sleepTimerProvider.notifier);
    return PopupMenuButton<int>(
      tooltip: l.sleepTimer,
      icon: Icon(timer.active ? Icons.bedtime : Icons.bedtime_outlined,
          color: timer.active ? Theme.of(context).colorScheme.primary : null),
      onSelected: (v) {
        switch (v) {
          case 0:
            notifier.cancel();
          case -1:
            notifier.startAtTrackEnd();
          default:
            notifier.startMinutes(v);
        }
      },
      itemBuilder: (_) => [
        for (final m in const [15, 30, 45, 60])
          PopupMenuItem(value: m, child: Text(l.sleepMinutes(m))),
        PopupMenuItem(value: -1, child: Text(l.sleepEndOfTrack)),
        if (timer.active)
          PopupMenuItem(value: 0, child: Text(l.sleepCancel)),
      ],
    );
  }
}
