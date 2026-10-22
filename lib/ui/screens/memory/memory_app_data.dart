import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/memory_providers.dart';
import '../../../services/memory/app_data.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/section_header.dart';
import 'memory_widgets.dart';

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

/// «Dati dell'app»: what the app keeps besides the music, and «Svuota cache».
class MemoryAppDataSection extends ConsumerWidget {
  const MemoryAppDataSection({super.key});

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showConfirm(
      context,
      title: l.memoryClearTitle,
      body: l.memoryClearBody,
      confirmLabel: l.memoryClearConfirm,
    );
    if (!ok) return;
    try {
      final r = await ref.read(memoryActionsProvider).clearCaches();
      ref.invalidate(appDataUsageProvider);
      final size = formatBytes(r.freedBytes);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              r.jamSkipped
                  ? l.memoryClearedJamKept(size)
                  : l.memoryCleared(size),
            ),
          ),
        );
    } on Object catch (e, st) {
      AppLog.e('clearing the caches failed', e, st);
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l.memoryClearFailed)));
    }
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
          data: (items) => Column(
            children: [
              for (final i in items)
                WeightRow(
                  title: _label(l, i.kind),
                  subtitle: i.detailBytes == null
                      ? null
                      : l.memoryCoversThumbs(formatBytes(i.detailBytes!)),
                  bytes: i.bytes,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CcDims.margin,
            12,
            CcDims.margin,
            0,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => _clear(context, ref),
              icon: const Icon(Icons.cleaning_services_rounded),
              label: Text(l.memoryClearCache),
            ),
          ),
        ),
      ],
    );
  }
}
