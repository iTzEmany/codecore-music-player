import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../services/jam/jam_models.dart';
import '../../theme/tokens.dart';
import 'jam_parts.dart' show JamAvatar;

/// Top of the Jam screen: back, «Jam», the end / leave button and the
/// participants. The only part of the screen that differs from the player.
class JamHeader extends StatelessWidget {
  const JamHeader({
    super.key,
    required this.jam,
    required this.isHost,
    required this.onEnd,
  });

  final JamState jam;
  final bool isHost;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CcDims.gap4,
            CcDims.gap8,
            CcDims.margin,
            CcDims.gap4,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: l.back,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Text(l.jamTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  // Collection-style pill, as the header actions.
                  child: OutlinedButton(
                    onPressed: onEnd,
                    style: isHost
                        ? OutlinedButton.styleFrom(
                            foregroundColor: context.cc.error,
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
            CcDims.gap12,
          ),
          child: JamParticipants(jam: jam),
        ),
      ],
    );
  }
}

/// Overlapping initials, then the host's name with the «host» tag.
class JamParticipants extends StatelessWidget {
  const JamParticipants({super.key, required this.jam});

  final JamState jam;

  static const _size = 32.0, _step = 22.0;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final ps = jam.participants;
    final host = ps.where((p) => p.id == jam.hostDeviceId).firstOrNull;
    final n = ps.length;
    return Row(
      children: [
        SizedBox(
          width: n == 0 ? 0 : _size + _step * (n - 1),
          height: _size + 4,
          child: Stack(
            children: [
              for (var i = 0; i < n; i++)
                Positioned(
                  left: i * _step,
                  top: 0,
                  child: Tooltip(
                    message: ps[i].name,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cc.bg, width: 2),
                      ),
                      child: JamAvatar(name: ps[i].name, size: _size),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (host != null) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              '${host.name}, ${context.l10n.jamHostTag}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cc.textMuted),
            ),
          ),
        ],
      ],
    );
  }
}

