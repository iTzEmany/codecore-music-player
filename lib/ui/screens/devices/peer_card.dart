import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../services/share/discovery.dart';
import '../../theme/tokens.dart';

/// A nearby device with its two short actions.
class PeerCard extends StatelessWidget {
  const PeerCard({
    super.key,
    required this.peer,
    required this.onJam,
    required this.onSend,
  });

  final Peer peer;
  final VoidCallback onJam, onSend;

  static IconData platformIcon(String p) => switch (p) {
    'android' => Icons.smartphone_rounded,
    'windows' || 'linux' => Icons.computer_rounded,
    _ => Icons.devices_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final l = context.l10n;
    final theme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: cc.surface2,
        borderRadius: BorderRadius.circular(CcDims.rCard),
      ),
      child: Row(
        children: [
          Icon(platformIcon(peer.platform), color: cc.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyLarge,
                ),
                Text(
                  peer.host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall?.copyWith(color: cc.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onJam,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Text(l.devicesJamShort),
          ),
          const SizedBox(width: 6),
          FilledButton(
            onPressed: onSend,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Text(l.devicesSendShort),
          ),
        ],
      ),
    );
  }
}
