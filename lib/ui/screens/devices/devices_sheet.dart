import '../../widgets/cc_sheet.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/jam_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/share_hub.dart';
import '../../../services/share/discovery.dart';
import '../../theme/tokens.dart';
import '../jam/jam_screen.dart';
import '../share/share_screen.dart';
import '../share/track_picker_screen.dart';
import 'peer_card.dart';

/// «Dispositivi»: the active Jam and the nearby devices, with [Jam] / [Invia].
class DevicesSheet extends ConsumerStatefulWidget {
  const DevicesSheet({super.key, this.trackIds});

  /// Tracks preselected by the caller (track or album menu); null = ask.
  final List<int>? trackIds;

  static Future<void> show(BuildContext context, {List<int>? trackIds}) =>
      showCcSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        builder: (_) => DevicesSheet(trackIds: trackIds),
      );

  @override
  ConsumerState<DevicesSheet> createState() => _DevicesSheetState();
}

class _DevicesSheetState extends ConsumerState<DevicesSheet> {
  late final ShareHubNotifier _hub;

  @override
  void initState() {
    super.initState();
    // Captured now: `ref` must not be used from dispose().
    _hub = ref.read(shareHubProvider.notifier);
    unawaited(_hub.enter());
  }

  @override
  void dispose() {
    _hub.leave();
    super.dispose();
  }

  Future<void> _send(Peer peer) async {
    final l = context.l10n;
    final nav = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    var ids = widget.trackIds;
    if (ids == null) {
      final picked = await nav.push<Set<int>>(
        MaterialPageRoute(builder: (_) => const TrackPickerScreen(initial: {})),
      );
      if (picked == null || picked.isEmpty) return;
      ids = picked.toList();
    }
    final List<Track> tracks = await ref
        .read(trackRepositoryProvider)
        .getByIds(ids);
    if (tracks.isEmpty) return;
    final ok = await _hub.sendOffer(peer, tracks);
    if (!mounted) return;
    nav.maybePop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(ok ? l.offerSent(peer.name) : l.shareErrUnreachable),
        ),
      );
  }

  void _startJam(Peer peer) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (!ref.read(jamProvider).active) {
      unawaited(ref.read(jamProvider.notifier).request(peer));
    }
    nav.pop();
    nav.push(MaterialPageRoute<void>(builder: (_) => const JamScreen()));
  }

  void _openJam() {
    final nav = Navigator.of(context, rootNavigator: true);
    nav.pop();
    nav.push(MaterialPageRoute<void>(builder: (_) => const JamScreen()));
  }

  void _manual() {
    final nav = Navigator.of(context, rootNavigator: true);
    nav.pop();
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ShareScreen(initialTrackIds: widget.trackIds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final hub = ref.watch(shareHubProvider);
    final jam = ref.watch(jamProvider);
    final visible = ref.watch(settingsProvider.select((s) => s.receiveFromLan));
    final ownId = _hub.deviceId ?? '';
    final others = [
      for (final p in jam.jam?.participants ?? const [])
        if (p.id != ownId) p.name,
    ];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(CcDims.margin, 0, CcDims.margin, 16),
        children: [
          Text(l.devicesTitle, style: theme.titleMedium),
          const SizedBox(height: 12),
          if (jam.active) ...[
            Text(
              l.devicesJamActive,
              style: theme.labelLarge?.copyWith(color: cc.textMuted),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: cc.surface2,
                borderRadius: BorderRadius.circular(CcDims.rCard),
              ),
              child: Row(
                children: [
                  Icon(Icons.queue_music_rounded, color: cc.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          others.isEmpty ? jam.peerName : others.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyLarge,
                        ),
                        Text(
                          l.jamParticipantsCount(others.length + 1),
                          style: theme.labelSmall?.copyWith(
                            color: cc.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(onPressed: _openJam, child: Text(l.jamOpen)),
                  TextButton(
                    onPressed: () {
                      unawaited(ref.read(jamProvider.notifier).end());
                      Navigator.of(context).pop();
                    },
                    child: Text(jam.isHost ? l.jamEnd : l.jamLeave),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            l.nearbyDevices,
            style: theme.labelLarge?.copyWith(color: cc.textMuted),
          ),
          const SizedBox(height: 4),
          for (final peer in hub.peers)
            PeerCard(
              peer: peer,
              onJam: () => _startJam(peer),
              onSend: () => _send(peer),
            ),
          if (hub.peers.isEmpty) ...[
            if (!visible) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l.devicesVisibleHint, style: theme.bodyMedium),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.devicesVisibleTitle),
                value: visible,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .update((s) => s.copyWith(receiveFromLan: v)),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hub.active ? l.noDevicesHint : l.searchingDevices,
                        style: theme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link_rounded),
            title: Text(l.manualConnection),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _manual,
          ),
        ],
      ),
    );
  }
}
