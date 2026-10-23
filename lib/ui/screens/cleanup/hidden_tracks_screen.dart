import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/duplicate_providers.dart';
import '../../../providers/selection_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/track_row.dart';
import '../../widgets/track_row_selection.dart';

/// Settings → Hidden tracks: the duplicates a merge hid, with «Restore» (one
/// by one from the ⋮ menu, or several at once from the selection bar).
class HiddenTracksScreen extends ConsumerWidget {
  const HiddenTracksScreen({super.key});

  static const _key = 'hidden';

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    Set<int> ids,
  ) async {
    final l = context.l10n;
    await ref.read(trackRepositoryProvider).setIgnored(ids, false);
    ref.read(selectionProvider(_key).notifier).clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l.hiddenRestored(ids.length))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tracks = ref.watch(hiddenTracksProvider).value ?? const [];
    final compact = ref.watch(settingsProvider).compactMode;
    final picked = ref.watch(selectionProvider(_key));
    final selection = RowSelection(
      listKey: _key,
      visibleIds: [for (final t in tracks) t.id],
    );
    final extent = trackRowExtentOf(context, compact);
    final notifier = ref.read(selectionProvider(_key).notifier);
    return SelectionScope(
      listKey: _key,
      visibleIds: selection.visibleIds,
      child: Scaffold(
        appBar: picked.active
            ? PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: SelectionBarFrame(
                  count: picked.count,
                  onClose: notifier.clear,
                  onSelectAll: () => notifier.selectAll(selection.visibleIds),
                  actions: [
                    IconButton(
                      key: const ValueKey('restore-selected'),
                      tooltip: l.hiddenRestore,
                      icon: const Icon(Icons.visibility_outlined),
                      onPressed: () => _restore(context, ref, picked.ids),
                    ),
                  ],
                ),
              )
            : AppBar(title: Text(l.hiddenTracksTitle)),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: tracks.isEmpty
                ? EmptyState(
                    icon: Icons.visibility_off_outlined,
                    message: l.hiddenTracksEmpty,
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(CcDims.margin),
                        child: Text(
                          l.hiddenTracksHint,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.cc.textMuted),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: tracks.length,
                          itemExtent: extent,
                          itemBuilder: (_, i) => LiveTrackRow(
                            track: tracks[i],
                            compact: compact,
                            selection: selection,
                            onTap: () {},
                            onMore: () =>
                                _restore(context, ref, {tracks[i].id}),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
