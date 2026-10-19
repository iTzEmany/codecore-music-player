import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/library_providers.dart';
import '../../services/library/track_editor.dart';
import '../../services/library/track_file_sync.dart';
import '../../providers/tag_backup_providers.dart';
import '../widgets/confirm.dart';
import '../widgets/tag_write_ui.dart';

/// A dialog on wide screens, a full page under 600 px.
Future<void> showTrackEditDialog(BuildContext context, Track track) {
  if (MediaQuery.sizeOf(context).width < 600) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _TrackEditDialog(track: track, page: true),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (_) => _TrackEditDialog(track: track),
  );
}

class _TrackEditDialog extends ConsumerStatefulWidget {
  const _TrackEditDialog({required this.track, this.page = false});

  final Track track;
  final bool page;

  @override
  ConsumerState<_TrackEditDialog> createState() => _TrackEditDialogState();
}

class _TrackEditDialogState extends ConsumerState<_TrackEditDialog> {
  late final _title = TextEditingController(text: widget.track.title);
  late final _artist = TextEditingController(text: widget.track.artist ?? '');
  late final _album = TextEditingController(text: widget.track.album ?? '');
  late final _albumArtist = TextEditingController(
    text: widget.track.albumArtist ?? '',
  );
  late final _year = TextEditingController(text: '${widget.track.year ?? ''}');
  late final _number = TextEditingController(
    text: '${widget.track.trackNumber ?? ''}',
  );
  late final _genre = TextEditingController(text: widget.track.genre ?? '');
  bool _titleEmpty = false;

  @override
  void dispose() {
    for (final c in [
      _title,
      _artist,
      _album,
      _albumArtist,
      _year,
      _number,
      _genre,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _titleEmpty = true);
      return;
    }
    final editor = ref.read(trackEditorProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final edit = TrackEdit(
      title: _title.text,
      artist: _artist.text,
      album: _album.text,
      albumArtist: _albumArtist.text,
      year: int.tryParse(_year.text.trim()),
      trackNumber: int.tryParse(_number.text.trim()),
      genre: _genre.text,
    );
    await editor.save(widget.track, edit);
    // A file that cannot be rewritten is skipped; the library edit stands.
    final blocked = await ref.read(
      tagWritableProvider(widget.track.path).future,
    );
    final outcome = blocked != null
        ? TagFileOutcome.none
        : await editor.writeToFiles([widget.track], (_) => edit.toChanges());
    showTagFileOutcome(messenger, l, outcome);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _restore() async {
    final l = context.l10n;
    final ok = await showConfirm(
      context,
      title: l.confirmRestoreTitle,
      body: l.confirmRestoreBody,
      confirmLabel: l.restoreFromFile,
    );
    if (!ok || !mounted) return;
    await ref.read(trackEditorProvider).restoreFromFile(widget.track);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool number = false,
    String? error,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : null,
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        isDense: true,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final form = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _field(
          _title,
          l.fieldTitle,
          error: _titleEmpty ? l.titleRequired : null,
        ),
        _field(_artist, l.fieldArtist),
        _field(_album, l.fieldAlbum),
        _field(_albumArtist, l.fieldAlbumArtist),
        Row(
          children: [
            Expanded(child: _field(_year, l.fieldYear, number: true)),
            const SizedBox(width: 12),
            Expanded(child: _field(_number, l.fieldTrackNumber, number: true)),
          ],
        ),
        _field(_genre, l.fieldGenre),
        AlsoInFileTile(path: widget.track.path),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _restore,
            child: Text(l.restoreFromFile),
          ),
        ),
      ],
    );
    if (widget.page) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l.editInfo),
          actions: [TextButton(onPressed: _save, child: Text(l.save))],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: form,
        ),
      );
    }
    return AlertDialog(
      title: Text(l.editInfo),
      content: SingleChildScrollView(child: form),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}
