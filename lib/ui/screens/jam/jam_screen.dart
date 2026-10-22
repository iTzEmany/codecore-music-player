import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/jam_providers.dart';
import '../../../providers/share_hub.dart';
import '../../../services/jam/jam_guest.dart';
import '../../../services/jam/jam_models.dart';
import '../share/track_picker_screen.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/artist_avatar.dart';
import '../../widgets/ring_progress.dart' show NowPlayingDot;
import 'jam_player_card.dart';
import '../../../providers/database_providers.dart';

/// The Jam: waiting for the answer, then the shared queue and controls.
class JamScreen extends ConsumerStatefulWidget {
  const JamScreen({super.key});

  @override
  ConsumerState<JamScreen> createState() => _JamScreenState();
}

class _JamScreenState extends ConsumerState<JamScreen> {
  bool _popped = false;

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
    final ids = await Navigator.of(context).push<Set<int>>(
      MaterialPageRoute(builder: (_) => const TrackPickerScreen()),
    );
    if (ids == null || ids.isEmpty || !mounted) return;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final tracks = await ref
        .read(trackRepositoryProvider)
        .getByIds(ids.toList());
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingAvatars(names: [s.peerName]),
                const SizedBox(height: 24),
                Text(l.jamWaiting(s.peerName), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: ctrl.cancelRequest,
                  child: Text(l.cancel),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final jam = s.jam;
    if (!s.active || jam == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.jamTitle)),
        body: Center(child: Text(l.jamWaitingEmpty)),
      );
    }
    final ownId = ref.read(shareHubProvider.notifier).deviceId ?? '';
    final isHost = s.isHost;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;

    String owner(JamItem i) {
      if (i.ownerDeviceId == ownId) return l.jamYou;
      final n = jam.nameOf(i.ownerDeviceId);
      return n.isEmpty ? s.peerName : n;
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        4,
                        8,
                        CcDims.margin,
                        8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: l.back,
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          Text(l.jamTitle, style: theme.headlineSmall),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: ctrl.end,
                                style: isHost
                                    ? FilledButton.styleFrom(
                                        backgroundColor: cc.error,
                                        foregroundColor: cc.bg,
                                      )
                                    : null,
                                child: Text(
                                  isHost ? l.jamEnd : l.jamLeave,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        CcDims.margin,
                        0,
                        CcDims.margin,
                        12,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _Participants(
                          jam: jam,
                          ownId: ownId,
                          hostId: jam.hostDeviceId,
                        ),
                      ),
                    ),
                    JamPlayerCard(state: s),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        CcDims.margin,
                        16,
                        CcDims.margin,
                        4,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(l.jamQueue, style: theme.titleMedium),
                      ),
                    ),
                    Expanded(
                      child: jam.items.isEmpty
                          ? Center(child: Text(l.jamEmpty))
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.only(bottom: 88),
                              buildDefaultDragHandles: false,
                              proxyDecorator: (child, _, anim) =>
                                  ccDragProxy(context, child, anim),
                              itemCount: jam.items.length,
                              onReorderItem: (from, to) {
                                ctrl.send(
                                  JamCommand.move(jam.items[from].id, to),
                                );
                              },
                              itemBuilder: (_, i) {
                                final it = jam.items[i];
                                final isCurrent = i == jam.currentIndex;
                                final canRemove =
                                    isHost ||
                                    (it.ownerDeviceId == ownId && !isCurrent);
                                final who = owner(it);
                                return ListTile(
                                  key: ValueKey(it.id),
                                  leading: SizedBox(
                                    width: 36,
                                    child: Center(
                                      child: isCurrent
                                          ? const NowPlayingDot()
                                          : _Avatar(name: who, size: 32),
                                    ),
                                  ),
                                  title: Text(
                                    it.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isCurrent ? cc.accent : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      if (it.artist != null) it.artist!,
                                      l.jamAddedBy(who),
                                      if (!it.available) l.jamUnavailable,
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: isHost
                                      ? () => ctrl.send(JamCommand.jump(it.id))
                                      : null,
                                  // The ✕ only appears where the removal is allowed.
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (canRemove)
                                        IconButton(
                                          tooltip: l.delete,
                                          icon: const Icon(Icons.close),
                                          onPressed: () => ctrl.send(
                                            JamCommand.remove(it.id),
                                          ),
                                        ),
                                      ReorderableDragStartListener(
                                        index: i,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.drag_handle_rounded,
                                            color: cc.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                Positioned(
                  right: CcDims.margin,
                  bottom: CcDims.margin,
                  child: FloatingActionButton.extended(
                    backgroundColor: cc.accent,
                    foregroundColor: cc.onAccent,
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: Text(l.jamAddTracks),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Initials on a tint taken from the name.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hue = artistHue(name);
    final color = HSLColor.fromAHSL(1, hue, 0.45, 0.32).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        artistMonogram(name),
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: context.cc.text,
        ),
      ),
    );
  }
}

class _Participants extends StatelessWidget {
  const _Participants({
    required this.jam,
    required this.ownId,
    required this.hostId,
  });

  final JamState jam;
  final String ownId, hostId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in jam.participants)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: p.name,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Avatar(name: p.name, size: 32),
                    if (p.id == hostId)
                      Text(
                        l.jamHostTag,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(fontSize: 10, color: cc.textMuted),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Avatars that pulse while the other device answers (still when the user
/// asked for fewer animations).
class _PulsingAvatars extends StatefulWidget {
  const _PulsingAvatars({required this.names});

  final List<String> names;

  @override
  State<_PulsingAvatars> createState() => _PulsingAvatarsState();
}

class _PulsingAvatarsState extends State<_PulsingAvatars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final n in widget.names)
          Transform.scale(
            scale: 1 + 0.12 * _c.value,
            child: _Avatar(name: n, size: 72),
          ),
      ],
    ),
  );
}
