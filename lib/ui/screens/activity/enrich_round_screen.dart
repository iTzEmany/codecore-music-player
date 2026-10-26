import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/activity_log_providers.dart';
import '../../../providers/enrich_completer_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/online/enrich_parts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_body.dart';
import '../../widgets/cc_app_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/track_row.dart';

String enrichPartLabel(AppLocalizations l, EnrichPart p) => switch (p) {
  EnrichPart.meta => l.enrichPartMeta,
  EnrichPart.lyrics => l.enrichPartLyrics,
  EnrichPart.synced => l.enrichPartSynced,
  EnrichPart.curio => l.enrichPartCurio,
  EnrichPart.credits => l.enrichPartCredits,
};

/// The songs of one round of the background completion: those that got
/// something and those that were asked in vain, each with the part.
class EnrichRoundScreen extends ConsumerWidget {
  const EnrichRoundScreen({super.key, required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final compact = ref.watch(settingsProvider).compactMode;
    final ctrl = ref.read(playerControllerProvider);
    final extent = trackRowExtentOf(context, compact);
    return Scaffold(
      appBar: CcAppBar(title: l.enrichRoundTitle),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: AsyncBody(
            value: ref.watch(enrichRoundProvider(entry)),
            onRetry: () => ref.invalidate(enrichRoundProvider(entry)),
            data: (round) {
              if (round.updated.isEmpty && round.none.isEmpty) {
                return EmptyState(
                  icon: Icons.auto_fix_high_rounded,
                  message: l.enrichRoundGone,
                );
              }
              final groups = [
                (l.enrichRoundUpdated, round.updated),
                (l.enrichRoundNone, round.none),
              ];
              return ListView(
                children: [
                  for (final (title, rows) in groups)
                    if (rows.isNotEmpty) ...[
                      SectionHeader(title),
                      for (var i = 0; i < rows.length; i++)
                        SizedBox(
                          height: extent,
                          child: LiveTrackRow(
                            track: rows[i].track,
                            compact: compact,
                            subtitleSuffix: enrichPartLabel(l, rows[i].part),
                            onTap: () => ctrl.playFromList(
                              [for (final r in rows) r.track],
                              i,
                              context: const PlayContext(PlayContextKind.library),
                            ),
                          ),
                        ),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
