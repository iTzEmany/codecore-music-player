import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/jam_remote_providers.dart';
import '../../../services/jam/jam_gate.dart';
import 'settings_pages.dart';

/// Blocked and suspended senders of Jam requests, with the way back. Nothing when both lists are empty.
class JamGateGroups extends ConsumerWidget {
  const JamGateGroups({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(jamGateProvider);
    final l = context.l10n;
    // The getters do not notify; the gate does.
    return ListenableBuilder(
      listenable: gate,
      builder: (context, _) {
        final blocked = gate.blocked, suspended = gate.suspended;
        String until(JamGateEntry e) => e.when == null
            ? l.jamUntilJamEnds
            : l.jamSuspendedUntil(MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(e.when!)));
        Widget tile(JamGateEntry e, String? sub, void Function(String) undo) => ListTile(
              title: Text(e.name),
              subtitle: sub == null ? null : Text(sub),
              trailing: TextButton(onPressed: () => undo(e.id), child: Text(l.jamUnblock)),
            );
        return Column(children: [
          if (blocked.isNotEmpty)
            SettingsGroup(title: l.jamBlockedTitle, children: [
              for (final e in blocked) tile(e, null, gate.unblock),
            ]),
          if (suspended.isNotEmpty)
            SettingsGroup(title: l.jamSuspendedTitle, children: [
              for (final e in suspended) tile(e, until(e), gate.unsuspend),
            ]),
        ]);
      },
    );
  }
}
