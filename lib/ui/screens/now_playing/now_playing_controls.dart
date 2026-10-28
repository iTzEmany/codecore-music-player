import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform.dart';
import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/jam_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/sleep_timer_provider.dart';
import '../../../services/audio/play_queue.dart';
import '../../theme/tokens.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/play_buttons.dart';
import '../../widgets/quality_tag.dart';
import '../../widgets/seek_bar.dart';
import '../../widgets/smooth_position.dart';
import '../../widgets/speed_button.dart';
import '../devices/devices_sheet.dart';
import 'queue_sheet.dart';
import '../../widgets/shuffle_button.dart';

/// «Elapsed · bar · total» (tap the total for the rest), the quality tag and
/// the speed centred below.
class NpSeekRow extends ConsumerStatefulWidget {
  const NpSeekRow({super.key, required this.track});

  final Track track;

  @override
  ConsumerState<NpSeekRow> createState() => _NpSeekRowState();
}

/// Inset from the page margin shared by the title, the seek row and the glyphs
/// of the 48 px icon buttons at the row ends.
const npEdge = 12.0;

class _NpSeekRowState extends ConsumerState<NpSeekRow> {
  final _smooth = SmoothPosition();
  bool _remaining = false;

  @override
  void initState() {
    super.initState();
    _smooth.followPlayer(ref);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _smooth.bindTickerMode(context);
  }

  @override
  void dispose() {
    _smooth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: cc.textMuted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final dur = ref.watch(durationProvider).value ?? Duration.zero;
    // Never below the widest «m:ss», so the bar does not move as time runs.
    const side = BoxConstraints(minWidth: 44);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: npEdge),
          child: Row(
            children: [
              ConstrainedBox(
                constraints: side,
                child: SeekTime(position: _smooth, duration: dur, style: style),
              ),
              // The ring is the one slider for a screen reader (±5 s).
              Expanded(
                child: ExcludeSemantics(
                  // Accent bar and soft knob, as in the mockup.
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: cc.accent,
                      inactiveTrackColor: cc.surface3,
                      thumbColor: cc.accentSoft,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayColor: cc.accent.withValues(alpha: 0.28),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                    ),
                    child: SeekBar(
                      position: _smooth,
                      duration: dur,
                      onSeek: (d) => ref.read(playerControllerProvider).seek(d),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _remaining = !_remaining),
                child: ConstrainedBox(
                  constraints: side.copyWith(minHeight: 48),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _remaining
                        ? SeekTime(
                            position: _smooth,
                            duration: dur,
                            remaining: true,
                            style: style,
                          )
                        : Text(formatDuration(dur.inMilliseconds), style: style),
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QualityTag(widget.track),
            const SizedBox(width: 8),
            const SpeedButton(),
          ],
        ),
      ],
    );
  }
}

/// Shuffle · previous · play · next · repeat.
class NpControls extends ConsumerWidget {
  const NpControls({super.key, this.live = false});

  /// A radio: no shuffle and no repeat, only the stations' own previous / next.
  final bool live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final playing = ref.watch(isPlayingProvider).value ?? false;
    final loading = ref.watch(streamLoadingProvider).value ?? false;
    final repeat = ref.watch(repeatProvider).value ?? PlayRepeat.off;
    final ctrl = ref.read(playerControllerProvider);
    final repeatOn = repeat != PlayRepeat.off;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!live) const ShuffleModeButton(),
        IconButton(
          tooltip: l.previousTrack,
          iconSize: 36,
          onPressed: ctrl.previous,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        if (loading)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox.square(
              dimension: 40,
              child: CircularProgressIndicator(
                key: const ValueKey('np-controls-loading'),
                semanticsLabel: l.playerLoading,
              ),
            ),
          )
        else
          PlayCircleButton(
            size: 64,
            playing: playing,
            onPressed: ctrl.togglePlayPause,
          ),
        IconButton(
          tooltip: l.nextTrack,
          iconSize: 36,
          onPressed: ctrl.next,
          icon: const Icon(Icons.skip_next_rounded),
        ),
        if (!live)
          IconButton(
            tooltip: l.repeat,
            onPressed: ctrl.cycleRepeat,
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  repeat == PlayRepeat.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  color: repeatOn ? cc.accent : cc.textMuted,
                ),
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: repeatOn ? cc.accent : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Devices (or «Jam» while one is active) · sleep timer chip · queue.
class NpBottomRow extends ConsumerWidget {
  const NpBottomRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final jam = ref.watch(jamProvider).active;
    return Column(
      children: [
        if (isDesktop) const _VolumeRow(),
        Row(
          children: [
            // Equal side slots keep the sleep chip at the exact centre.
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => DevicesSheet.show(context),
                  icon: Icon(
                    Icons.devices_rounded,
                    size: 20,
                    color: jam ? cc.accent : cc.textMuted,
                  ),
                  label: Text(
                    jam ? l.devicesJamShort : l.devicesTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: jam ? cc.accent : cc.textMuted),
                  ),
                ),
              ),
            ),
            const _SleepChip(),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => showQueueSheet(context),
                  icon: Icon(
                    Icons.queue_music_rounded,
                    size: 20,
                    color: cc.textMuted,
                  ),
                  label: Text(
                    l.queue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cc.textMuted),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Width of both side slots of the volume row (mute button, percentage).
const _volumeSlot = 48.0;

class _VolumeRow extends ConsumerWidget {
  const _VolumeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(volumeProvider);
    final n = ref.read(volumeProvider.notifier);
    return Row(
      children: [
        // The desktop theme shrink-wraps the button: fix the slot width.
        SizedBox(
          width: _volumeSlot,
          child: IconButton(
            tooltip: context.l10n.mute,
            onPressed: n.toggleMute,
            icon: Icon(
              v == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            ),
          ),
        ),
        Expanded(
          child: Slider(value: v, onChanged: n.set),
        ),
        SizedBox(
          width: _volumeSlot,
          child: Text(
            '${(v * 100).round()}%',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.cc.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _SleepChip extends ConsumerStatefulWidget {
  const _SleepChip();

  @override
  ConsumerState<_SleepChip> createState() => _SleepChipState();
}

class _SleepChipState extends ConsumerState<_SleepChip> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // The remaining minutes change slowly: refresh twice a minute.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && ref.read(sleepTimerProvider).endsAt != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final timer = ref.watch(sleepTimerProvider);
    final notifier = ref.read(sleepTimerProvider.notifier);
    String? label;
    if (timer.endsAt != null) {
      final left = timer.endsAt!.difference(DateTime.now());
      final min = (left.inSeconds / 60).ceil().clamp(1, 9999);
      label = '$min′';
    } else if (timer.atTrackEnd) {
      label = l.sleepChipEnd;
    }
    return PopupMenuButton<int>(
      key: const Key('np-sleep-chip'),
      tooltip: l.sleepTimer,
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
        if (timer.active) PopupMenuItem(value: 0, child: Text(l.sleepCancel)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CcDims.gap12,
          vertical: CcDims.gap8,
        ),
        decoration: BoxDecoration(
          color: timer.active ? cc.accent.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(CcDims.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              timer.active ? Icons.bedtime_rounded : Icons.bedtime_outlined,
              size: 20,
              color: timer.active ? cc.accentSoft : cc.textMuted,
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: cc.accentSoft),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
