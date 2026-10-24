import '../../widgets/cc_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/tag_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm.dart';
import '../settings/accent_picker.dart';

/// The colour of a tag (an index into the eight accents), or null.
Color? tagColor(BuildContext context, UserTag t) {
  final i = t.color;
  if (i == null || i < 0 || i >= CcAccent.values.length) return null;
  return buildPalette(
    context.cc.isLight ? AppThemeId.chiaro : AppThemeId.notte,
    CcAccent.values[i],
  ).accent;
}

class TagDot extends StatelessWidget {
  const TagDot(this.tag, {super.key, this.size = 12});

  final UserTag tag;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: tagColor(context, tag) ?? context.cc.surface3,
    ),
  );
}

/// Asks for a name; null when cancelled.
Future<String?> askTagName(BuildContext context, {String? initial, String? title}) {
  final controller = TextEditingController(text: initial);
  final l = context.l10n;
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title ?? l.tagNew),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) => Navigator.of(c).pop(v.trim().isEmpty ? null : v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            final v = controller.text.trim();
            Navigator.of(c).pop(v.isEmpty ? null : v);
          },
          child: Text(l.save),
        ),
      ],
    ),
  );
}

/// Rename, colour and delete of one tag, from its row's menu.
Future<void> editTag(BuildContext context, WidgetRef ref, TagSummary s) async {
  final l = context.l10n;
  final repo = ref.read(tagRepositoryProvider);
  final action = await showCcSheet<String>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l.tagRename),
            onTap: () => Navigator.of(c).pop('rename'),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.tagColor),
            onTap: () => Navigator.of(c).pop('color'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: Text(l.delete),
            onTap: () => Navigator.of(c).pop('delete'),
          ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case 'rename':
      final name = await askTagName(context, initial: s.tag.name, title: l.tagRename);
      if (name == null || !context.mounted) return;
      if (!await repo.rename(s.tag.id, name) && context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l.tagNameTaken)));
      }
    case 'color':
      final picked = await showDialog<int?>(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text(l.tagColor),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CcDims.gap24, vertical: CcDims.gap8),
              child: AccentPicker(
                theme: c.cc.isLight ? AppThemeId.chiaro : AppThemeId.notte,
                selected: CcAccent.values[(s.tag.color ?? 0).clamp(0, CcAccent.values.length - 1)],
                onSelected: (a) => Navigator.of(c).pop(a.index),
              ),
            ),
            TextButton(onPressed: () => Navigator.of(c).pop(-1), child: Text(l.tagNoColor)),
          ],
        ),
      );
      if (picked != null) await repo.setColor(s.tag.id, picked < 0 ? null : picked);
    case 'delete':
      final ok = await showConfirm(
        context,
        title: l.tagDeleteTitle(s.tag.name),
        body: l.tagDeleteBody,
        confirmLabel: l.delete,
        destructive: true,
      );
      if (ok) await repo.delete(s.tag.id);
  }
}

/// «Etichette…»: check or uncheck tags for [tracks]. With several tracks a tag
/// that only some of them carry shows a dash; tapping gives it to all.
Future<void> showTagsSheet(BuildContext context, WidgetRef ref, List<Track> tracks) =>
    showCcSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TagsSheet(tracks: tracks),
    );

class _TagsSheet extends ConsumerStatefulWidget {
  const _TagsSheet({required this.tracks});

  final List<Track> tracks;

  @override
  ConsumerState<_TagsSheet> createState() => _TagsSheetState();
}

class _TagsSheetState extends ConsumerState<_TagsSheet> {
  Map<int, int> _counts = const {};
  bool _loaded = false;

  List<int> get _ids => [for (final t in widget.tracks) t.id];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final counts = await ref.read(tagRepositoryProvider).countsAmong(_ids);
    if (mounted) {
      setState(() {
        _counts = counts;
        _loaded = true;
      });
    }
  }

  Future<void> _toggle(UserTag tag) async {
    final repo = ref.read(tagRepositoryProvider);
    final n = widget.tracks.length;
    if ((_counts[tag.id] ?? 0) == n) {
      await repo.unassign(_ids, tag.id);
    } else {
      await repo.assign(_ids, tag.id);
    }
    await _reload();
  }

  Future<void> _create() async {
    final name = await askTagName(context);
    if (name == null) return;
    final repo = ref.read(tagRepositoryProvider);
    final id = await repo.create(name);
    await repo.assign(_ids, id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tags = ref.watch(tagsProvider).value ?? const [];
    final n = widget.tracks.length;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: Text(l.tagNew),
              onTap: _create,
            ),
            Flexible(
              child: ListView.builder(
                // Many entries already exceed the max height, so lazy changes nothing visible.
                shrinkWrap: tags.length <= 20,
                itemCount: tags.length,
                itemBuilder: (_, i) {
                  final s = tags[i];
                  return CheckboxListTile(
                      tristate: true,
                      value: !_loaded
                          ? false
                          : (_counts[s.tag.id] ?? 0) == 0
                          ? false
                          : (_counts[s.tag.id] ?? 0) == n
                          ? true
                          : null,
                      onChanged: _loaded ? (_) => _toggle(s.tag) : null,
                      secondary: TagDot(s.tag),
                      title: Text(s.tag.name),
                      subtitle: Text(l.tracksCount(s.trackCount)),
                    );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add a tag to, or take one from, a whole selection: pick the tag in a list.
/// [remove] lists only the tags the tracks carry.
Future<void> pickTagFor(
  BuildContext context,
  WidgetRef ref,
  List<Track> tracks, {
  required bool remove,
  VoidCallback? done,
}) async {
  final l = context.l10n;
  final repo = ref.read(tagRepositoryProvider);
  final ids = [for (final t in tracks) t.id];
  final all = ref.read(tagsProvider).value ?? await repo.watchAll().first;
  final carried = remove ? await repo.countsAmong(ids) : const <int, int>{};
  final choices = [
    for (final s in all)
      if (!remove || carried.containsKey(s.tag.id)) s,
  ];
  if (!context.mounted) return;
  if (remove && choices.isEmpty) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l.tagNoneToRemove)));
    return;
  }
  final picked = await showCcSheet<UserTag>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.7),
        child: ListView.builder(
          // Many entries already exceed the max height, so lazy changes nothing visible.
          shrinkWrap: choices.length <= 20,
          itemCount: choices.length + (remove ? 0 : 1),
          itemBuilder: (_, k) {
            if (!remove && k == 0) {
              return ListTile(
                leading: const Icon(Icons.add_rounded),
                title: Text(l.tagNew),
                onTap: () async {
                  final name = await askTagName(c);
                  if (name == null || !c.mounted) return;
                  final id = await repo.create(name);
                  final tag = await repo.byName(name);
                  if (tag != null && c.mounted && tag.id == id) Navigator.of(c).pop(tag);
                },
              );
            }
            final s = choices[remove ? k : k - 1];
            return ListTile(
              leading: TagDot(s.tag),
              title: Text(s.tag.name),
              subtitle: Text(l.tracksCount(s.trackCount)),
              onTap: () => Navigator.of(c).pop(s.tag),
            );
          },
        ),
      ),
    ),
  );
  if (picked == null) return;
  int changed;
  if (remove) {
    changed = await repo.unassign(ids, picked.id);
  } else {
    await repo.assign(ids, picked.id);
    changed = ids.length; // all of them carry it now, even if some already did
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          remove
              ? l.tagUnassigned(changed, picked.name)
              : l.tagAssigned(changed, picked.name),
        ),
      ),
    );
  done?.call();
}
