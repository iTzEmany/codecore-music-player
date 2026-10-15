import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../core/app_info.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/online_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../widgets/confirm.dart';
import '../../widgets/cover_image.dart';
import '../library/folders_sheet.dart';
import '../../../providers/share_providers.dart';
import '../playlists/playlist_dialogs.dart';
import '../share/share_screen.dart';
import '../../../services/migration/python_db_importer.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import 'missing_tracks_screen.dart';
import 'theme_swatch.dart';

const _languages = {
  'it': 'Italiano',
  'en': 'English',
  'de': 'Deutsch',
  'es': 'Español',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final folders = ref.watch(foldersProvider).value ?? const [];
    final missing = ref.watch(missingTracksProvider).value ?? const [];
    Widget header(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(t,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
        );
    return ListView(children: [
      header(l.settingsAppearance),
      ListTile(
        title: Text(l.settingsTheme),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(runSpacing: 8, children: [
            for (final (id, label, colors) in [
              ('notte', l.themeNotte, CcColors.notte),
              ('oled', l.themeOled, CcColors.oled),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ThemeSwatch(
                  label: label,
                  colors: colors,
                  selected: appThemeIdFromName(s.theme).name == id,
                  onTap: () =>
                      notifier.update((c) => c.copyWith(theme: id)),
                ),
              ),
          ]),
        ),
      ),
      ListTile(
        title: Text(l.settingsTextSize),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SegmentedButton<double>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 0.9, label: Text(l.textSmall)),
              ButtonSegment(value: 1.0, label: Text(l.textNormal)),
              ButtonSegment(value: 1.15, label: Text(l.textLarge)),
            ],
            selected: {s.fontScale},
            onSelectionChanged: (v) =>
                notifier.update((c) => c.copyWith(fontScale: v.first)),
          ),
        ),
      ),
      SwitchListTile(
        title: Text(l.settingsCompact),
        value: s.compactMode,
        onChanged: (v) => notifier.update((c) => c.copyWith(compactMode: v)),
      ),
      SwitchListTile(
        title: Text(l.settingsReducedMotion),
        value: s.reducedMotion,
        onChanged: (v) => notifier.update((c) => c.copyWith(reducedMotion: v)),
      ),
      header(l.settingsLanguage),
      RadioGroup<String>(
        groupValue: s.language,
        onChanged: (v) {
          if (v != null) notifier.update((c) => c.copyWith(language: v));
        },
        child: Column(children: [
          for (final e in _languages.entries)
            RadioListTile<String>(value: e.key, title: Text(e.value)),
        ]),
      ),
      header(l.settingsPlayback),
      SwitchListTile(
        title: Text(l.normalizeVolume),
        subtitle: Text(l.normalizeVolumeHint),
        value: s.normalizeVolume,
        onChanged: (v) =>
            notifier.update((c) => c.copyWith(normalizeVolume: v)),
      ),
      header(l.settingsLibrary),
      for (final f in folders)
        ListTile(
          leading: const Icon(Icons.folder),
          title: Text(f.path, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            tooltip: l.removeFolder,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => confirmRemoveFolder(context, ref, f.id),
          ),
        ),
      ListTile(
        leading: const Icon(Icons.create_new_folder),
        title: Text(l.addFolder),
        onTap: () => addFolderAndScan(ref),
      ),
      ListTile(
        leading: const Icon(Icons.refresh),
        title: Text(l.rescanNow),
        onTap: () => scanWithPermission(ref),
      ),
      ListTile(
        leading: const Icon(Icons.image_not_supported_outlined),
        title: Text(l.clearCoverCache),
        onTap: () => _clearCovers(context, ref),
      ),
      if (missing.isNotEmpty)
        ListTile(
          leading: const Icon(Icons.report_problem_outlined),
          title: Text(l.missingTracksCount(missing.length)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const MissingTracksScreen())),
        ),
      header(l.shareTitle),
      ListTile(
        leading: const Icon(Icons.wifi_tethering),
        title: Text(l.shareTitle),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ShareScreen())),
      ),
      SwitchListTile(
        title: Text(l.receiveFromLan),
        subtitle: Text(l.receiveFromLanHint),
        value: s.receiveFromLan,
        // The hub reacts to this setting (service, notification, discovery).
        onChanged: (v) =>
            notifier.update((c) => c.copyWith(receiveFromLan: v)),
      ),
      ListTile(
        leading: const Icon(Icons.badge_outlined),
        title: Text(l.shareDeviceName),
        subtitle: Text(ref.watch(deviceNameProvider)),
        onTap: () => _editDeviceName(context, ref),
      ),
      ListTile(
        leading: const Icon(Icons.history),
        title: Text(l.importOld),
        subtitle: Text(l.importOldHint),
        onTap: () => _importOld(context, ref),
      ),
      header(l.settingsOnline),
      ListTile(
        leading: const Icon(Icons.travel_explore),
        title: Text(l.enrichLibrary),
        onTap: () => _enrichLibrary(context, ref),
      ),
      SwitchListTile(
        title: Text(l.autoEnrich),
        subtitle: Text(l.autoEnrichHint),
        value: s.autoEnrich,
        onChanged: (v) => notifier.update((c) => c.copyWith(autoEnrich: v)),
      ),
      SwitchListTile(
        title: Text(l.autoLyrics),
        subtitle: Text(l.autoLyricsHint),
        value: s.autoLyrics,
        onChanged: (v) => notifier.update((c) => c.copyWith(autoLyrics: v)),
      ),
      header(l.settingsAbout),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(l.appVersion(kAppVersion)),
      ),
      ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(l.licenses),
        onTap: () => showLicensePage(context: context),
      ),
    ]);
  }

  Future<void> _importOld(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.pickFiles();
    final path = picked.isEmpty ? null : picked.first.path;
    if (path == null) return;
    String text;
    try {
      final s = await PythonDbImporter(ref.read(databaseProvider)).import(path);
      text = l.importSummary(s.favorites, s.playlists, s.lyrics, s.unmatched);
    } on Object catch (e, st) {
      AppLog.w('python import failed', e, st);
      text = l.importFailed;
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _editDeviceName(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final name = await askPlaylistName(context,
        initial: ref.read(deviceNameProvider),
        confirmLabel: l.save,
        title: l.shareDeviceName,
        label: l.shareDeviceName);
    if (name == null) return;
    ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(deviceName: name));
  }

  Future<void> _enrichLibrary(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ids = (await ref.read(tracksProvider(false).future))
        .where((t) => t.enrichStatus != 2)
        .map((t) => t.id)
        .toList();
    if (!context.mounted) return;
    final minutes = (ids.length * 3 / 60).ceil();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.enrichConfirmTitle),
        content: Text(l.enrichConfirmBody(ids.length, minutes)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: Text(l.apply)),
        ],
      ),
    );
    if (ok != true) return;
    final started = ref.read(enrichJobProvider.notifier).start(ids);
    if (!started && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l.enrichBusy)));
    }
  }

  Future<void> _clearCovers(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final msg = l.coverCacheCleared;
    final ok = await showConfirm(context,
        title: l.confirmClearCoversTitle,
        body: l.confirmClearCoversBody,
        confirmLabel: l.clearCoverCache);
    if (!ok || !context.mounted) return;
    try {
      final dir = ref.read(coversDirProvider);
      if (await dir.exists()) {
        await for (final e in dir.list()) {
          if (e is File) await e.delete();
        }
      }
      await ref.read(trackRepositoryProvider).resetCovers();
      ref.invalidate(coverFileProvider);
    } on Object catch (e, st) {
      AppLog.e('clear covers failed', e, st);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
    await scanWithPermission(ref);
  }
}

