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
import '../../widgets/empty_state.dart';
import '../../widgets/ring_progress.dart';
import 'jam_parts.dart';
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
        body: EmptyState(
          icon: Icons.group_outlined,
          message: l.jamWaitingEmpty,
        ),
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

    final endLabel = Text(
      isHost ? l.jamEnd : l.jamLeave,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          4,
                          8,
                          CcDims.margin,
                          4,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: l.back,
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                            Text(l.jamTitle, style: theme.titleLarge),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                // Collection-style pill, as the header actions.
                                child: OutlinedButton(
                                  onPressed: ctrl.end,
                                  style: isHost
                                      ? OutlinedButton.styleFrom(
                                          foregroundColor: cc.error,
                                        )
                                      : null,
                                  child: endLabel,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          CcDims.margin,
                          0,
                          CcDims.margin,
                          12,
                        ),
                        child: JamParticipants(jam: jam),
                      ),
                    ),
                    SliverToBoxAdapter(child: JamPlayerCard(state: s)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          CcDims.margin,
                          16,
                          CcDims.margin,
                          4,
                        ),
                        child: Text(l.jamQueue, style: theme.titleMedium),
                      ),
                    ),
                    if (jam.items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.queue_music_rounded,
                          message: l.jamEmpty,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 88),
                        sliver: SliverReorderableList(
                          proxyDecorator: (child, _, anim) =>
                              ccDragProxy(context, child, anim),
                          itemCount: jam.items.length,
                          onReorderItem: (from, to) {
                            ctrl.send(JamCommand.move(jam.items[from].id, to));
                          },
                          itemBuilder: (_, i) {
                            final it = jam.items[i];
                            final isCurrent = i == jam.currentIndex;
                            return JamQueueRow(
                              key: ValueKey(it.id),
                              item: it,
                              who: owner(it),
                              isCurrent: isCurrent,
                              canRemove:
                                  isHost ||
                                  (it.ownerDeviceId == ownId && !isCurrent),
                              index: i,
                              onTap: isHost
                                  ? () => ctrl.send(JamCommand.jump(it.id))
                                  : null,
                              onRemove: () =>
                                  ctrl.send(JamCommand.remove(it.id)),
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
            child: RingProgress(
              size: 96,
              stroke: 4,
              live: true,
              child: JamAvatar(
                name: n,
                size: RingProgress.innerSize(96, stroke: 4),
              ),
            ),
          ),
      ],
    ),
  );
}
