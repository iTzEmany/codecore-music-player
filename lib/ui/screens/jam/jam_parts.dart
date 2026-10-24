import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/import_providers.dart';
import '../../../providers/share_hub.dart';
import '../../../services/jam/jam_models.dart';
import '../../theme/app_theme.dart' show ccIconDensity;
import '../../theme/tokens.dart';
import '../../widgets/artist_avatar.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/ring_progress.dart' show NowPlayingDot;

/// Initials on a tint taken from the name.
class JamAvatar extends StatelessWidget {
  const JamAvatar({super.key, required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = HSLColor.fromAHSL(1, artistHue(name), 0.45, 0.32).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        artistMonogram(name),
        style: Theme.of(context).textTheme.titleSmall!.sized(size * 0.38),
      ),
    );
  }
}

/// The cover of an item this device added (its [JamItem.ref] is the local
/// track id); the other devices' items have no cover in the protocol.
class JamCover extends ConsumerWidget {
  const JamCover({
    super.key,
    required this.item,
    required this.size,
    this.radius = CcDims.rList,
  });

  final JamItem? item;
  final double size, radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final it = item;
    final ownId = ref.read(shareHubProvider.notifier).deviceId;
    final own = it != null && it.ownerDeviceId == ownId;
    final id = own ? int.tryParse(it.ref ?? '') : null;
    final key = id == null
        ? null
        : ref.watch(importedTrackProvider(id)).value?.coverKey;
    return CoverImage(coverKey: key, size: size, radius: radius);
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

/// A row of the shared queue, laid out like a row of the play queue.
class JamQueueRow extends StatelessWidget {
  const JamQueueRow({
    super.key,
    required this.item,
    required this.who,
    required this.isCurrent,
    required this.canRemove,
    required this.index,
    this.onTap,
    required this.onRemove,
  });

  final JamItem item;
  final String who;
  final bool isCurrent, canRemove;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final l = context.l10n;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CcDims.margin,
          vertical: 4,
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                JamCover(item: item, size: 48),
                if (isCurrent)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cc.bg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(CcDims.rList),
                    ),
                    alignment: Alignment.center,
                    child: const NowPlayingDot(),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (item.artist != null) item.artist!,
                      l.jamAddedBy(who),
                      if (!item.available) l.jamUnavailable,
                    ].join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall,
                  ),
                ],
              ),
            ),
            // The ✕ only appears where the removal is allowed.
            if (canRemove)
              IconButton(
                tooltip: l.delete,
                visualDensity: ccIconDensity,
                icon: Icon(Icons.close, color: cc.textMuted),
                onPressed: onRemove,
              ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.drag_handle_rounded, color: cc.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
