import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../core/paths.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/theme_providers.dart';
import '../../../services/export/save_file.dart';
import '../../../services/theme/background_image.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm.dart';
import 'accent_picker.dart';
import 'theme_editor_screen.dart';
import 'theme_swatch.dart';

/// The largest theme file taken in: a theme is a few hundred bytes.
const _maxThemeFileBytes = 256 * 1024;

/// «Tema» and «Colore di accento» of Impostazioni → Aspetto: the built-in
/// themes, the user's own, and what can be done with them.
class ThemeTiles extends ConsumerStatefulWidget {
  const ThemeTiles({super.key});

  @override
  ConsumerState<ThemeTiles> createState() => _ThemeTilesState();
}

class _ThemeTilesState extends ConsumerState<ThemeTiles> {
  @override
  void initState() {
    super.initState();
    // Pictures of themes that are gone are not kept.
    WidgetsBinding.instance.addPostFrameCallback((_) => _prune());
  }

  Future<void> _prune() async {
    try {
      final keep = {
        for (final t in ref.read(customThemesProvider).items)
          if (t.background.imagePath != null) t.background.imagePath!,
      };
      await pruneBackgroundImages(await themeDir(), keep);
    } on Object catch (e, st) {
      AppLog.w('could not tidy the theme pictures', e, st);
    }
  }

  void _select(String value) =>
      ref.read(settingsProvider.notifier).update((s) => s.copyWith(theme: value));

  void _edit(CustomTheme t) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ThemeEditorScreen(initial: t)),
  );

  /// A new theme starts as a copy of what is in use.
  void _new() {
    final l = context.l10n;
    final s = ref.read(settingsProvider);
    final customs = ref.read(customThemesProvider);
    if (customs.items.length >= kMaxCustomThemes) {
      _say(l.themeLimit);
      return;
    }
    final id = ref.read(customThemesProvider.notifier).newId();
    final name = '${l.themeEditorTitle} ${customs.items.length + 1}';
    final current = customThemeIdOf(s.theme) == null ? null : customs.byId(customThemeIdOf(s.theme)!);
    final start = current != null
        ? current.withId(id).copyWith(name: name)
        : CustomTheme(
            id: id,
            name: name,
            base: appThemeIdFromName(s.theme),
            overrides: accentFromName(s.accent) == CcAccent.viola
                ? const {}
                : {CcToken.accent: buildPalette(appThemeIdFromName(s.theme), accentFromName(s.accent)).accent},
          );
    _edit(start);
  }

  void _duplicate(CustomTheme t) {
    final l = context.l10n;
    final n = ref.read(customThemesProvider.notifier);
    final copy = t.withId(n.newId()).copyWith(name: l.themeCopyName(t.name));
    if (!n.put(copy)) return _say(l.themeLimit);
    _select(customThemeSettingValue(copy.id));
  }

  Future<void> _export(CustomTheme t) async {
    final slug = t.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    final bytes = Uint8List.fromList(utf8.encode(t.forExport().encode()));
    try {
      await saveBytes('${slug.isEmpty ? 'tema' : slug}.codecore-theme.json', bytes, mimeType: 'application/json');
    } on Object catch (e, st) {
      AppLog.w('could not export the theme', e, st);
    }
  }

  Future<void> _import() async {
    final l = context.l10n;
    final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['json']);
    final path = res.isEmpty ? null : res.first.path;
    if (path == null) return;
    CustomTheme? t;
    try {
      final f = File(path);
      if (await f.length() <= _maxThemeFileBytes) t = CustomTheme.decode(await f.readAsString());
    } on Object catch (e, st) {
      AppLog.w('could not read the theme file', e, st);
    }
    if (!mounted) return;
    if (t == null) return _say(l.themeImportFailed);
    final n = ref.read(customThemesProvider.notifier);
    // Another id (the file may come from this very device), and no picture.
    final imported = t.forExport().withId(n.newId());
    if (!n.put(imported)) return _say(l.themeLimit);
    _select(customThemeSettingValue(imported.id));
    _say(l.themeImported);
  }

  void _delete(CustomTheme t) {
    final l = context.l10n;
    final wasActive = ref.read(settingsProvider).theme == customThemeSettingValue(t.id);
    ref.read(customThemesProvider.notifier).remove(t.id);
    showUndoSnack(context, l.themeDeleted, () {
      ref.read(customThemesProvider.notifier).put(t);
      if (wasActive) _select(customThemeSettingValue(t.id));
    });
  }

  void _say(String text) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final customs = ref.watch(customThemesProvider);
    final accent = accentFromName(s.accent);
    final activeId = customThemeIdOf(s.theme);
    final active = activeId == null ? null : customs.byId(activeId);
    return Column(
      children: [
        ListTile(
          title: Text(l.settingsTheme),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              runSpacing: 8,
              children: [
                for (final (t, name) in [
                  (AppThemeId.notte, l.themeNotte),
                  (AppThemeId.oled, l.themeOled),
                  (AppThemeId.chiaro, l.themeChiaro),
                ])
                  _gap(ThemeSwatch(
                    label: name,
                    colors: buildPalette(t, accent),
                    selected: active == null && appThemeIdFromName(s.theme) == t,
                    onTap: () => _select(t.name),
                  )),
                for (final t in customs.items)
                  _gap(ThemeSwatch(
                    key: ValueKey('theme-${t.id}'),
                    label: t.name,
                    colors: t.resolve(),
                    selected: active?.id == t.id,
                    onTap: () => _select(customThemeSettingValue(t.id)),
                  )),
                _gap(ThemeSwatch(
                  key: const ValueKey('theme-new'),
                  label: l.themeNew,
                  colors: context.cc,
                  selected: false,
                  mark: Icons.add_rounded,
                  onTap: _new,
                )),
              ],
            ),
          ),
        ),
        if (active != null)
          ListTile(
            title: Text(active.name),
            subtitle: Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  key: const ValueKey('theme-edit'),
                  onPressed: () => _edit(active),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l.themeEdit),
                ),
                TextButton.icon(
                  key: const ValueKey('theme-duplicate'),
                  onPressed: () => _duplicate(active),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(l.themeDuplicate),
                ),
                TextButton.icon(
                  key: const ValueKey('theme-export'),
                  onPressed: () => _export(active),
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: Text(l.themeExport),
                ),
                TextButton.icon(
                  key: const ValueKey('theme-delete'),
                  onPressed: () => _delete(active),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(l.themeDelete),
                ),
              ],
            ),
          ),
        ListTile(
          key: const ValueKey('theme-import'),
          leading: const Icon(Icons.file_download_outlined),
          title: Text(l.themeImport),
          onTap: _import,
        ),
        if (active == null)
          ListTile(
            title: Text(l.settingsAccent),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AccentPicker(
                theme: appThemeIdFromName(s.theme),
                selected: accent,
                onSelected: (a) =>
                    ref.read(settingsProvider.notifier).update((c) => c.copyWith(accent: a.name)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _gap(Widget w) => Padding(padding: const EdgeInsets.only(right: 12), child: w);
}
