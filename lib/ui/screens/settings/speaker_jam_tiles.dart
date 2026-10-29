import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/speaker_providers.dart';

/// «Jam sulla cassa»: the switch, the devices marked so far (tap to change
/// the answer) and, when the permission was refused, the row to ask again.
class SpeakerJamTiles extends ConsumerWidget {
  const SpeakerJamTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(speakerChangesProvider);
    final l = context.l10n;
    final m = ref.watch(speakerMonitorProvider);
    return Column(
      children: [
        SwitchListTile(
          title: Text(l.speakerJamSection),
          subtitle: Text(l.speakerJamHint),
          value: m.enabled,
          onChanged: m.setEnabled,
        ),
        if (!m.permission && m.permissionAsked)
          ListTile(
            leading: const Icon(Icons.bluetooth_disabled_rounded),
            title: Text(l.speakerPermDenied),
            subtitle: Text(l.speakerPermRetry),
            onTap: m.askPermission,
          ),
        if (m.answers.isEmpty)
          ListTile(dense: true, title: Text(l.speakerNoDevices))
        else
          for (final e in m.answers.entries)
            SwitchListTile(
              secondary: const Icon(Icons.speaker_rounded),
              title: Text(e.value.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(e.value.isSpeaker ? l.speakerIsSpeaker : l.speakerNotSpeaker),
              value: e.value.isSpeaker,
              onChanged: (v) => m.answer(e.key, v),
            ),
      ],
    );
  }
}
