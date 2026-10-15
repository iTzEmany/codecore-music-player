import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/jam_providers.dart';
import '../../../providers/share_hub.dart';
import '../../../services/jam/jam_guest.dart';
import '../../../services/jam/jam_models.dart';
import '../share/track_picker_screen.dart';
import '../../../providers/database_providers.dart';

/// The Jam: waiting for the answer, then the shared queue and controls.
class JamScreen extends ConsumerStatefulWidget {
  const JamScreen({super.key});

  @override
  ConsumerState<JamScreen> createState() => _JamScreenState();
}

class _JamScreenState extends ConsumerState<JamScreen> {
  Timer? _tick;
  double? _dragging; // slider position while the user drags
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _dragging == null) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _leave(String? message) {
    if (_popped || !mounted) return;
    _popped = true;
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = ref.read(jamProvider.notifier);
    Navigator.of(context).pop();
    if (message != null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    Future<void>.microtask(ctrl.reset);
  }

  String _outcomeText(AppLocalizations l, JamUiState s) => switch (s.outcome) {
        JamJoinOutcome.declined => l.jamDeclined(s.peerName),
        JamJoinOutcome.busy => l.jamBusy(s.peerName),
        JamJoinOutcome.cancelled => '',
        _ => l.jamUnreachable,
      };

  Future<void> _add() async {
    final ids = await Navigator.of(context)
        .push<Set<int>>(MaterialPageRoute(builder: (_) => const TrackPickerScreen()));
    if (ids == null || ids.isEmpty || !mounted) return;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final tracks = await ref.read(trackRepositoryProvider).getByIds(ids.toList());
    final n = await ref.read(jamProvider.notifier).addTracks(tracks);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l.jamAdded(n))));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(jamProvider);
    ref.listen(jamProvider, (prev, next) {
      final l = context.l10n;
      if (next.phase == JamPhase.idle && next.outcome != null) {
        final t = _outcomeText(l, next);
        _leave(t.isEmpty ? null : t);
      } else if (next.phase == JamPhase.ended) {
        _leave(next.lost ? l.jamLost : l.jamEnded);
      }
    });
    final ctrl = ref.read(jamProvider.notifier);

    if (s.phase == JamPhase.requesting) {
      return Scaffold(
        appBar: AppBar(title: Text(l.jamTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l.jamWaiting(s.peerName), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                  onPressed: ctrl.cancelRequest, child: Text(l.cancel)),
            ]),
          ),
        ),
      );
    }

    final jam = s.jam;
    if (!s.active || jam == null) {
      return Scaffold(
          appBar: AppBar(title: Text(l.jamTitle)),
          body: const SizedBox.shrink());
    }
    final ownId = ref.read(shareHubProvider.notifier).deviceId ?? '';
    final isHost = s.isHost;
    final cur = jam.current;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dur = (cur?.durationMs ?? 0).toDouble();
    final pos = (_dragging ??
            jam.positionAtTime(now).toDouble().clamp(0, dur > 0 ? dur : 1))
        .toDouble();
    final iAmOutput = jam.outputDeviceId == ownId;

    String owner(JamItem i) =>
        i.ownerDeviceId == ownId ? l.jamYou : s.peerName;

    Future<void> guarded(Future<JamError?> f, {String? forbidden}) async {
      final messenger = ScaffoldMessenger.of(context);
      final e = await f;
      if (e == JamError.forbidden) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(forbidden ?? l.jamGuestCannotSkip)));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.jamWith(s.peerName)),
        actions: [
          TextButton(
            onPressed: ctrl.end,
            child: Text(isHost ? l.jamEnd : l.jamLeave),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(l.jamAddTracks),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cur == null ? l.jamNothingPlaying : l.jamNowPlaying,
                style: Theme.of(context).textTheme.labelMedium),
            if (cur != null) ...[
              Text(cur.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge),
              Text(cur.artist ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            Slider(
              value: pos.clamp(0, dur > 0 ? dur : 1).toDouble(),
              max: dur > 0 ? dur : 1,
              onChanged: cur == null || dur <= 0
                  ? null
                  : (v) => setState(() => _dragging = v),
              onChangeEnd: (v) {
                setState(() => _dragging = null);
                ctrl.send(JamCommand.seek(v.round()));
              },
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton.filled(
                iconSize: 36,
                tooltip: jam.playing ? l.pause : l.play,
                icon: Icon(jam.playing ? Icons.pause : Icons.play_arrow),
                onPressed: cur == null
                    ? null
                    : () => ctrl.send(jam.playing
                        ? const JamCommand.pause()
                        : const JamCommand.play()),
              ),
              if (isHost)
                IconButton(
                  tooltip: l.nextTrack,
                  icon: const Icon(Icons.skip_next),
                  onPressed: cur == null
                      ? null
                      : () => ctrl.send(const JamCommand.next()),
                ),
            ]),
            Row(children: [
              const Icon(Icons.volume_down),
              Expanded(
                child: Slider(
                  value: jam.volume.clamp(0.0, 1.0),
                  onChanged: (v) => ctrl.send(JamCommand.volume(v)),
                ),
              ),
              const Icon(Icons.volume_up),
            ]),
            Text(l.jamOutput, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: true, label: Text(l.jamOutputHere)),
                ButtonSegment(
                    value: false, label: Text(l.jamOutputOther(s.peerName))),
              ],
              selected: {iAmOutput},
              onSelectionChanged: (v) {
                ctrl.setOutput(v.first ? ownId : s.peerId);
              },
            ),
            const SizedBox(height: 12),
            Text(l.jamQueue, style: Theme.of(context).textTheme.titleMedium),
          ]),
        ),
        Expanded(
          child: jam.items.isEmpty
              ? Center(child: Text(l.jamEmpty))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: jam.items.length,
                  onReorderItem: (from, to) {
                    ctrl.send(JamCommand.move(jam.items[from].id, to));
                  },
                  itemBuilder: (_, i) {
                    final it = jam.items[i];
                    final isCurrent = i == jam.currentIndex;
                    final canRemove =
                        isHost || (it.ownerDeviceId == ownId && !isCurrent);
                    return ListTile(
                      key: ValueKey(it.id),
                      selected: isCurrent,
                      leading: Icon(isCurrent
                          ? Icons.graphic_eq
                          : Icons.music_note_outlined),
                      title: Text(it.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          [
                            if (it.artist != null) it.artist!,
                            l.jamAddedBy(owner(it)),
                            if (!it.available) l.jamUnavailable,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      onTap: isHost
                          ? () => ctrl.send(JamCommand.jump(it.id))
                          : null,
                      trailing: IconButton(
                        tooltip: l.delete,
                        icon: const Icon(Icons.close),
                        onPressed: canRemove
                            ? () => ctrl.send(JamCommand.remove(it.id))
                            : () => guarded(
                                Future.value(JamError.forbidden),
                                forbidden: l.jamRemoveForbidden),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
