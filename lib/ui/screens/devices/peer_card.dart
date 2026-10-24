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
    this.onPair,
    this.trusted = false,
  });

  final Peer peer;
  final VoidCallback onJam, onSend;

  /// Shown when the peer can be paired and is not yet.
  final VoidCallback? onPair;
  final bool trusted;

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CcDims.gap8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cc.surface2,
                  shape: BoxShape.circle,
                ),
                child: Icon(platformIcon(peer.platform), color: cc.textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(
                          peer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyLarge,
                        ),
                      ),
                      if (trusted) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: l.trustedBadge,
                          child: Icon(Icons.verified_user_outlined, size: 16, color: cc.accent),
                        ),
                      ],
                    ]),
                    Text(
                      peer.host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.labelSmall?.copyWith(color: cc.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onPair != null) ...[
                TextButton(onPressed: onPair, child: Text(l.pairAction)),
                const SizedBox(width: 8),
              ],
              OutlinedButton(
                onPressed: onJam,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: Text(l.devicesJamShort),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onSend,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: Text(l.devicesSendShort),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
