import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/library_providers.dart';
import '../../services/library/track_editor.dart';
import '../widgets/confirm.dart';

Future<void> showTrackEditDialog(BuildContext context, Track track) {
  return showDialog<void>(
    context: context,
    builder: (_) => _TrackEditDialog(track: track),
  );
}

class _TrackEditDialog extends ConsumerStatefulWidget {
  const _TrackEditDialog({required this.track});

  final Track track;

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
    await ref
        .read(trackEditorProvider)
        .save(
          widget.track,
          TrackEdit(
            title: _title.text,
            artist: _artist.text,
            album: _album.text,
            albumArtist: _albumArtist.text,
            year: int.tryParse(_year.text.trim()),
            trackNumber: int.tryParse(_number.text.trim()),
            genre: _genre.text,
          ),
        );
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
    return AlertDialog(
      title: Text(l.editInfo),
      content: SingleChildScrollView(
        child: Column(
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
            _field(_year, l.fieldYear, number: true),
            _field(_number, l.fieldTrackNumber, number: true),
            _field(_genre, l.fieldGenre),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _restore,
                child: Text(l.restoreFromFile),
              ),
            ),
          ],
        ),
      ),
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
