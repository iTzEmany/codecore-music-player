import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/jam_providers.dart';
import '../../../providers/speaker_providers.dart';
import '../../../services/jam/jam_models.dart';
import '../../../services/share/discovery.dart';
import '../../../services/jam/speaker_jam.dart';
import '../../theme/tokens.dart';
import '../../widgets/cc_sheet.dart';
import '../../widgets/show_msg.dart';
import 'jam_screen.dart';

/// Asks to join [peer]'s Jam and opens the Jam screen (same as the «Jam» button).
void joinAnnouncedJam(BuildContext context, WidgetRef ref, Peer peer) {
  final nav = Navigator.of(context, rootNavigator: true);
  unawaited(ref.read(jamProvider.notifier).request(peer));
  nav.push(MaterialPageRoute<void>(builder: (_) => const JamScreen()));
}

/// Sends a Jam command; a refusal for the missing speaker says so.
Future<void> sendJamCommand(
  BuildContext context,
  JamController ctrl,
  JamCommand cmd,
) async {
  final msg = context.l10n.speakerAwayNotice;
  final err = await ctrl.send(cmd);
  if (err == JamError.noSpeaker && context.mounted) showMsg(context, msg);
}

/// «Unisciti alla Jam di X» above the player; ✕ hides it for that Jam.
class JamInviteBanner extends ConsumerWidget {
  const JamInviteBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peer = ref.watch(announcedJamProvider);
    if (peer == null ||
        ref.watch(jamInviteDismissedProvider).contains(jamInviteKey(peer))) {
      return const SizedBox.shrink();
    }
    final l = context.l10n;
    final cc = context.cc;
    final text = l.jamInviteBanner(peer.jamName!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 4, CcDims.margin, 0),
      child: Material(
        color: cc.surface2,
        borderRadius: BorderRadius.circular(CcDims.dockRadius),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: text,
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => joinAnnouncedJam(context, ref, peer),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CcDims.gap12,
                      vertical: CcDims.gap12,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.queue_music_rounded, color: cc.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l.jamInviteDismiss,
              icon: const Icon(Icons.close_rounded),
              onPressed: () =>
                  ref.read(jamInviteDismissedProvider.notifier).hide(peer),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Collega una cassa» while the speaker's Jam waits for its speaker.
class SpeakerAwayNotice extends ConsumerWidget {
  const SpeakerAwayNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final away = ref.watch(
      jamProvider.select((j) => j.jam?.speakerAwaySince != null),
    );
    if (!away) return const SizedBox.shrink();
    final cc = context.cc;
    final text = context.l10n.speakerAwayNotice;
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 4, CcDims.margin, 0),
      child: Semantics(
        liveRegion: true,
        child: Material(
          color: cc.surface2,
          borderRadius: BorderRadius.circular(CcDims.dockRadius),
          child: Padding(
            padding: const EdgeInsets.all(CcDims.gap12),
            child: Row(
              children: [
                Icon(Icons.speaker_rounded, color: cc.accent),
                const SizedBox(width: 12),
                Expanded(child: Text(text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Guest side (R-119): the Jam is stopped and the guest's speaker is on.
/// Closing the sheet without choosing counts as «No».
Future<void> showSpeakerOffer(BuildContext context, SpeakerJam jam) async {
  var answered = false;
  await showCcSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      final l = ctx.l10n;
      void reply(bool yes) {
        answered = true;
        Navigator.of(ctx).pop();
        yes ? unawaited(jam.acceptOffer()) : jam.declineOffer();
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CcDims.margin,
            0,
            CcDims.margin,
            CcDims.margin,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l.speakerOfferTitle,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              Text(l.speakerOfferBody),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => reply(false),
                    child: Text(l.speakerNo),
                  ),
                  FilledButton(
                    onPressed: () => reply(true),
                    child: Text(l.speakerYes),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  if (!answered) jam.declineOffer();
}
