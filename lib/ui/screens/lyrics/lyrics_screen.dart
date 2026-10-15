import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/player_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/cover_backdrop.dart';
import '../../widgets/cover_image.dart';
import 'lyrics_view.dart';

/// Lyrics page: tinted backdrop, cover + title in the header, copy action.
/// [embedded] (desktop side panel) drops the app bar and the backdrop.
class LyricsScreen extends ConsumerWidget {
  const LyricsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final track = ref.watch(liveCurrentTrackProvider).value;
    if (track == null) {
      return Scaffold(
        backgroundColor: embedded ? Colors.transparent : null,
        appBar: embedded ? null : AppBar(title: Text(l.lyrics)),
        body: Center(child: Text(l.nothingPlaying)),
      );
    }
    if (embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: LyricsView(track: track),
      );
    }
    final plain = lyricsPlainText(track);
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: context.cc.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            CoverImage(coverKey: track.coverKey, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyLarge,
                  ),
                  Text(
                    track.artist ?? l.unknownArtist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (plain != null)
            IconButton(
              tooltip: l.copy,
              icon: const Icon(Icons.copy_rounded),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: plain));
                messenger
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(content: Text(l.copied)));
              },
            ),
        ],
      ),
      extendBodyBehindAppBar: false,
      body: CoverBackdrop(
        coverKey: track.coverKey,
        child: LyricsView(track: track),
      ),
    );
  }
}
