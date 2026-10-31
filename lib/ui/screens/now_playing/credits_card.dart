import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../data/db/app_database.dart' show Track;
import '../../../l10n/l10n_ext.dart';
import '../../../providers/credits_providers.dart';
import '../../../providers/online_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/online/enrich_parts.dart';
import '../../theme/tokens.dart';
import '../../widgets/credits_section.dart';
import '../../widgets/show_msg.dart';

/// «Crediti e dettagli» of the playing track, with the refresh button (when the
/// setting is on). Nothing at all when there is nothing to show or to ask for.
class CreditsCard extends ConsumerStatefulWidget {
  const CreditsCard({super.key, required this.track});

  final Track track;

  @override
  ConsumerState<CreditsCard> createState() => _CreditsCardState();
}

class _CreditsCardState extends ConsumerState<CreditsCard> {
  bool _busy = false;

  Future<void> _refresh() async {
    final t = widget.track;
    final l = context.l10n;
    setState(() => _busy = true);
    var failed = false;
    try {
      final out = await ref.read(enrichEngineProvider).completeOne(t.id, {
        EnrichPart.credits,
        EnrichPart.curio, // the switch is for the automatic search only
      }, force: true);
      final o = out[EnrichPart.credits];
      failed = o == PartOutcome.failed || o == PartOutcome.limited;
    } on Object catch (e, st) {
      AppLog.w('credits refresh failed', e, st);
      failed = true;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (failed) showMsg(context, l.creditsRefreshFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canRefresh = ref.watch(
      settingsProvider.select((s) => s.creditsDetails),
    );
    final data = ref.watch(trackCreditsProvider(widget.track.id)).value;
    final has =
        data != null && CreditsSection.hasContent(data.credits, data.details);
    if (!has && !canRefresh) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.cc.surface1,
        borderRadius: BorderRadius.circular(CcDims.rCard),
        child: Padding(
          padding: const EdgeInsets.all(CcDims.gap16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.creditsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (has) CreditsSection(data.credits, data.details),
              if (canRefresh)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _refresh,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(l.creditsRefresh),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
