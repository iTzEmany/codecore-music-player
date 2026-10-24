import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/memory_providers.dart';
import '../../../services/memory/app_data.dart';
import '../../theme/tokens.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/section_header.dart';
import 'memory_widgets.dart';
import '../../widgets/show_msg.dart';

String _label(AppLocalizations l, AppDataKind k) => switch (k) {
  AppDataKind.covers => l.memoryCovers,
  AppDataKind.database => l.memoryDatabase,
  AppDataKind.imageMemory => l.memoryImageMemory,
  AppDataKind.jamCache => l.memoryJamCache,
  AppDataKind.searchCache => l.memorySearchCache,
  AppDataKind.catalogCache => l.memoryCatalogCache,
  AppDataKind.suggestions => l.memorySuggestions,
  AppDataKind.blurCopies => l.memoryBlurCopies,
  AppDataKind.tagBackups => l.memoryTagBackups,
  AppDataKind.log => l.memoryLog,
  AppDataKind.podcasts => l.memoryPodcasts,
  AppDataKind.radio => l.memoryRadio,
};

/// Rows under 1 MB are not listed.
const _minBytes = 1024 * 1024;

/// «Dati dell'app»: what the app keeps besides the music, and «Svuota cache».
class MemoryAppDataSection extends ConsumerWidget {
  const MemoryAppDataSection({super.key});

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final locale = l.localeName;
    try {
      final r = await ref.read(memoryActionsProvider).clearCaches();
      ref.invalidate(appDataUsageProvider);
      final size = formatBytes(r.freedBytes, locale);
      if (!context.mounted) return;
      showMsg(context, r.jamSkipped
                  ? l.memoryClearedJamKept(size)
                  : l.memoryCleared(size));
    } on Object catch (e, st) {
      AppLog.e('clearing the caches failed', e, st);
      if (!context.mounted) return;
      showMsg(context, l.memoryClearFailed);
    }
  }

  Widget _rows(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    List<AppDataItem> items,
  ) {
    final locale = l.localeName;
    // The caches are one row: they are what «Svuota cache» frees.
    final cache = items
        .where((i) => clearableKinds.contains(i.kind))
        .fold(0, (n, i) => n + i.bytes);
    final rows = <({String title, String? meta, int bytes})>[
      for (final i in items)
        if (!clearableKinds.contains(i.kind))
          (
            title: _label(l, i.kind),
            meta: switch (i.kind) {
              AppDataKind.covers when i.detailBytes != null =>
                l.memoryCoversThumbs(formatBytes(i.detailBytes!, locale)),
              AppDataKind.database => l.memoryDatabaseHint,
              AppDataKind.tagBackups => l.memoryTagBackupsHint,
              _ => null,
            },
            bytes: i.bytes,
          ),
      (title: l.memoryCache, meta: l.memoryCacheHint, bytes: cache),
    ]..sort((a, b) => b.bytes.compareTo(a.bytes));
    final shown = [
      for (final r in rows)
        if (r.bytes >= _minBytes) r,
    ];
    final hidden = rows.any((r) => r.bytes > 0 && r.bytes < _minBytes);
    final theme = Theme.of(context).textTheme;
    final muted = theme.bodySmall?.copyWith(color: context.cc.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in shown)
          WeightRow(
            title: r.title,
            subtitle: r.meta,
            bytes: r.bytes,
            fraction: shareOf(r.bytes, shown.first.bytes),
          ),
        if (hidden)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CcDims.margin,
              CcDims.gap8,
              CcDims.margin,
              0,
            ),
            child: Text(l.memoryTinyNote, style: muted),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CcDims.margin,
            CcDims.gap16,
            CcDims.margin,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton(
                onPressed: cache > 0 ? () => _clear(context, ref) : null,
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                child: Text(l.memoryClearCache, maxLines: 1, softWrap: false),
              ),
              const SizedBox(height: 8),
              Text(l.memoryClearHint(formatBytes(cache, locale)), style: muted),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final usage = ref.watch(appDataUsageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l.memoryAppData),
        usage.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(CcDims.margin),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) {
            AppLog.w('app data sizes unavailable', e, st);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
              child: Text(l.memoryUnavailable),
            );
          },
          data: (items) => _rows(context, ref, l, items),
        ),
      ],
    );
  }
}
