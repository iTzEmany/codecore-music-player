import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/share_hub.dart';
import '../../../services/share/sync_client.dart';
import '../../../services/share/trusted_devices.dart';
import 'sync_preview_dialog.dart';

/// «Sincronizza playlist» with [device]: read its playlists, show what would
/// change, and write only after «Applica». Started only by the user.
Future<void> syncFlow(BuildContext context, WidgetRef ref, TrustedDevice device) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final hub = ref.read(shareHubProvider.notifier);
  void say(String m) => messenger.showSnackBar(SnackBar(content: Text(m)));
  try {
    final plan = await hub.planPlaylistSync(device);
    if (!context.mounted) return;
    final decision = await showSyncPreview(context, plan, canAsk: true);
    if (decision == null) return;
    await hub.applyPlaylistSync(plan);
    if (decision == SyncDecision.applyAndAsk) {
      say(l.syncAsked(await hub.askMissingTracks(device, plan)));
    } else {
      say(l.syncApplied(plan.toWrite.length));
    }
  } on SyncException catch (e) {
    say(switch (e.error) {
      SyncError.unreachable => l.syncUnreachable,
      SyncError.identityChanged => l.shareErrIdentity,
      _ => l.syncFailed,
    });
  } on Object catch (e, st) {
    AppLog.e('playlist sync failed', e, st);
    say(l.syncFailed);
  }
}
