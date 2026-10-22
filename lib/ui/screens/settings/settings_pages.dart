import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../core/app_info.dart';
import '../../../core/constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/equalizer_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/online_providers.dart';
import '../../../services/online/enrichment_service.dart' show needsEnrichment;
import '../../../providers/settings_providers.dart';
import '../../widgets/confirm.dart';
import '../../widgets/cover_image.dart';
import '../library/folders_sheet.dart';
import '../../../providers/share_providers.dart';
import '../../../providers/translation_providers.dart';
import '../../shell/shell_nav.dart';
import '../playlists/playlist_dialogs.dart';
import '../share/share_screen.dart';
import '../../../services/migration/python_db_importer.dart';
import '../../theme/tokens.dart';
import 'icon_follow_tile.dart';
import 'theme_tiles.dart';
import 'cleanup_tiles.dart';
import 'advanced_section.dart';
import 'backup_section.dart';
import 'download_settings_tiles.dart';
import 'equalizer_screen.dart';
import 'log_export_tile.dart';
import 'report_issue_tile.dart';
import 'missing_tracks_screen.dart';
import 'transition_settings_tiles.dart';
import 'trusted_devices_tiles.dart';
import 'translation_models_tiles.dart';
import 'update_tiles.dart';
import 'shuffle_plus_tiles.dart';
import 'release_settings_tiles.dart';

const _languages = {
  'it': 'Italiano',
  'en': 'English',
  'de': 'Deutsch',
  'es': 'Español',
  'fr': 'Français',
  'pt': 'Português',
};

/// Language name as shown in the picker and in the index summary.
String languageName(String code) => _languages[code] ?? code;

enum SettingsPage { appearance, playback, library, online, network, backup, advanced }

String settingsPageTitle(AppLocalizations l, SettingsPage p) => switch (p) {
      SettingsPage.appearance => l.settingsPageAppearance,
      SettingsPage.playback => l.settingsPagePlayback,
      SettingsPage.library => l.settingsPageLibrary,
      SettingsPage.online => l.settingsPageOnline,
      SettingsPage.network => l.settingsPageNetwork,
      SettingsPage.backup => l.settingsPageBackup,
      SettingsPage.advanced => l.settingsPageAdvanced,
    };

/// The groups of one settings page, in a scrolling column (max 760 wide).
class SettingsPageView extends ConsumerWidget {
  const SettingsPageView(this.page, {super.key});

  final SettingsPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = switch (page) {
      SettingsPage.appearance => _appearance(context, ref),
      SettingsPage.playback => _playback(context, ref),
      SettingsPage.library => _library(context, ref),
      SettingsPage.online => _online(context, ref),
      SettingsPage.network => _network(context, ref),
      SettingsPage.backup => _backup(context, ref),
      SettingsPage.advanced => _advanced(context, ref),
    };
    // A page with a single group needs no group title.
    final single = groups.length == 1;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            for (final g in groups)
              single ? SettingsGroup(children: g.children) : g,
          ],
        ),
      ),
    );
  }
}

List<SettingsGroup> _appearance(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final s = ref.watch(settingsProvider);
  final notifier = ref.read(settingsProvider.notifier);
  return [
            SettingsGroup(
              title: l.settingsAppearance,
              children: [
                const ThemeTiles(),
                const IconFollowTile(),
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
                      onSelectionChanged: (v) => notifier.update(
                        (c) => c.copyWith(fontScale: v.first),
                      ),
                    ),
                  ),
                ),
                SwitchListTile(
                  title: Text(l.settingsCompact),
                  value: s.compactMode,
                  onChanged: (v) =>
                      notifier.update((c) => c.copyWith(compactMode: v)),
                ),
                SwitchListTile(
                  title: Text(l.settingsReducedMotion),
                  value: s.reducedMotion,
                  onChanged: (v) =>
                      notifier.update((c) => c.copyWith(reducedMotion: v)),
                ),
              ],
            ),
            SettingsGroup(
              title: l.settingsLanguage,
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(_languages[s.language] ?? s.language),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickLanguage(context, ref),
                ),
              ],
            ),
  ];
}

List<SettingsGroup> _playback(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final s = ref.watch(settingsProvider);
  final notifier = ref.read(settingsProvider.notifier);
  return [
            SettingsGroup(
              title: l.settingsPlayback,
              children: [
                if (ref.watch(equalizerProvider) != null)
                  ListTile(
                    leading: const Icon(Icons.equalizer_rounded),
                    title: Text(l.equalizer),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ShellNav.open<void>(context, const EqualizerScreen()),
                  ),
                const TransitionSettingsTiles(),
                const ShufflePlusTiles(),
                SwitchListTile(
                  title: Text(l.settingsRecordHistory),
                  subtitle: Text(l.settingsRecordHistoryHint),
                  value: s.recordHistory,
                  onChanged: (v) =>
                      notifier.update((c) => c.copyWith(recordHistory: v)),
                ),
                SwitchListTile(
                  title: Text(l.normalizeVolume),
                  subtitle: Text(l.normalizeVolumeHint),
                  value: s.normalizeVolume,
                  onChanged: (v) =>
                      notifier.update((c) => c.copyWith(normalizeVolume: v)),
                ),
              ],
            ),
  ];
}

List<SettingsGroup> _library(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final folders = ref.watch(foldersProvider).value ?? const [];
  final missing = ref.watch(missingTracksProvider).value ?? const [];
  return [
            SettingsGroup(
              title: l.settingsLibrary,
              children: [
                for (final f in folders)
                  ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(
                      f.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MissingTracksScreen(),
                      ),
                    ),
                  ),
              ],
            ),
            SettingsGroup(
              title: l.cleanupSection,
              children: cleanupTiles(context, ref),
            ),
  ];
}

List<SettingsGroup> _online(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final s = ref.watch(settingsProvider);
  final notifier = ref.read(settingsProvider.notifier);
  return [
            SettingsGroup(
              title: l.settingsOnline,
              children: [
                ListTile(
                  leading: const Icon(Icons.travel_explore),
                  title: Text(l.enrichLibrary),
                  onTap: () => _enrichLibrary(context, ref),
                ),
                SwitchListTile(
                  title: Text(l.autoEnrich),
                  subtitle: Text(l.autoEnrichHint),
                  value: s.autoEnrich,
                  onChanged: (v) =>
                      notifier.update((c) => c.copyWith(autoEnrich: v)),
                ),
                SwitchListTile(
                  title: Text(l.autoLyrics),
                  subtitle: Text(l.autoLyricsHint),
                  value: s.autoLyrics,
                  onChanged: (v) =>
                      notifier.update((c) => c.copyWith(autoLyrics: v)),
                ),
              ],
            ),
            if (kEnableYoutube)
              SettingsGroup(
                title: l.newReleasesTitle,
                children: const [ReleaseSettingsTiles()],
              ),
            if (kEnableYoutube)
              SettingsGroup(
                title: l.settingsDownloads,
                children: const [DownloadSettingsTiles()],
              ),
            if (ref.watch(lyricsTranslatorProvider) != null)
              SettingsGroup(
                title: l.translationModels,
                children: const [TranslationModelsTiles()],
              ),
  ];
}

List<SettingsGroup> _network(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final s = ref.watch(settingsProvider);
  final notifier = ref.read(settingsProvider.notifier);
  return [
            SettingsGroup(
              title: l.settingsLocalNetwork,
              children: [
                ListTile(
                  leading: const Icon(Icons.wifi_tethering),
                  title: Text(l.shareTitle),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ShareScreen(),
                    ),
                  ),
                ),
                SwitchListTile(
                  title: Text(l.receiveFromLan),
                  subtitle: Text(l.receiveFromLanHint),
                  value: s.receiveFromLan,
                  // The hub reacts to this setting (service, notification, discovery).
                  onChanged: (v) =>
                      notifier.update((c) => c.copyWith(receiveFromLan: v)),
                ),
                ownFingerprintTile(context, ref),
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
              ],
            ),
      ..._trustedGroup(context, ref),
  ];
}

List<SettingsGroup> _backup(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  return [
            SettingsGroup(
              title: l.backupSection,
              children: backupTiles(context, ref),
            ),
  ];
}

List<SettingsGroup> _advanced(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  return [
            SettingsGroup(
              title: l.settingsAdvanced,
              children: const [AdvancedSettingsTiles()],
            ),
            SettingsGroup(
              title: l.settingsAbout,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.appVersion(kAppVersion)),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l.licenses),
                  onTap: () => showLicensePage(context: context),
                ),
                ...updateTiles(context, ref),
                const LogExportTile(),
                const ReportIssueTile(),
              ],
            ),
  ];
}

Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final notifier = ref.read(settingsProvider.notifier);
  final current = ref.read(settingsProvider).language;
  final picked = await showDialog<String>(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(l.settingsLanguage),
      children: [
        for (final e in _languages.entries)
          ListTile(
            title: Text(e.value),
            trailing: e.key == current
                ? Icon(Icons.check_rounded, color: c.cc.accent)
                : null,
            onTap: () => Navigator.of(c).pop(e.key),
          ),
      ],
    ),
  );
  if (picked != null) notifier.update((s) => s.copyWith(language: picked));
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
  final name = await askPlaylistName(
    context,
    initial: ref.read(deviceNameProvider),
    confirmLabel: l.save,
    title: l.shareDeviceName,
    label: l.shareDeviceName,
  );
  if (name == null) return;
  ref
      .read(settingsProvider.notifier)
      .update((s) => s.copyWith(deviceName: name));
}

Future<void> _enrichLibrary(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  // Only what still has something missing: the estimate is honest and
  // tracks already complete are not asked about again.
  final ids = (await ref.read(trackRepositoryProvider).watchTracks().first)
      .where((t) => needsEnrichment(t))
      .map((t) => t.id)
      .toList();
  if (!context.mounted) return;
  if (ids.isEmpty) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l.enrichNothingToDo)));
    return;
  }
  final minutes = (ids.length * 3 / 60).ceil();
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l.enrichConfirmTitle),
      content: Text(l.enrichConfirmBody(ids.length, minutes)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(c).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(c).pop(true),
          child: Text(l.apply),
        ),
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
  final ok = await showConfirm(
    context,
    title: l.confirmClearCoversTitle,
    body: l.confirmClearCoversBody,
    confirmLabel: l.clearCoverCache,
  );
  if (!ok || !context.mounted) return;
  try {
    final dir = ref.read(coversDirProvider);
    if (await dir.exists()) {
      await for (final e in dir.list()) {
        if (e is File) await e.delete();
      }
    }
    await ref.read(trackRepositoryProvider).resetCovers();
    ref.invalidate(coverIndexProvider);
  } on Object catch (e, st) {
    AppLog.e('clear covers failed', e, st);
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(msg)));
  await scanWithPermission(ref);
}

/// «Dispositivi fidati»: only once something is paired.
List<SettingsGroup> _trustedGroup(BuildContext context, WidgetRef ref) {
  final tiles = trustedDevicesTiles(context, ref);
  if (tiles.isEmpty) return const [];
  return [SettingsGroup(title: context.l10n.trustedSection, children: tiles)];
}

/// A (optionally titled) group of settings on a rounded surface.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 20, CcDims.margin, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(title!, style: Theme.of(context).textTheme.titleMedium),
            ),
          Material(
            color: cc.surface1,
            borderRadius: BorderRadius.circular(CcDims.rCard),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
