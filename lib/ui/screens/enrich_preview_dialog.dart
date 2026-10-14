import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/online_providers.dart';
import '../../services/online/enrichment_service.dart';
import '../../services/online/http_client.dart';

Future<void> showEnrichPreview(BuildContext context, Track track) {
  return showDialog<void>(
      context: context, builder: (_) => _EnrichPreviewDialog(track: track));
}

class _Row {
  const _Row(this.field, this.label, this.current, this.proposed);

  final EnrichField field;
  final String label;
  final String? current, proposed;
}

class _EnrichPreviewDialog extends ConsumerStatefulWidget {
  const _EnrichPreviewDialog({required this.track});

  final Track track;

  @override
  ConsumerState<_EnrichPreviewDialog> createState() => _State();
}

class _State extends ConsumerState<_EnrichPreviewDialog> {
  EnrichmentProposal? _proposal;
  bool _loading = true;
  bool _rateLimited = false;
  final _selected = <EnrichField>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ref
          .read(enrichmentServiceProvider)
          .propose(widget.track);
      if (!mounted) return;
      setState(() {
        _proposal = p;
        _loading = false;
      });
    } on RateLimitedException {
      if (!mounted) return;
      setState(() {
        _rateLimited = true;
        _loading = false;
      });
    }
  }

  List<_Row> _rows(BuildContext context) {
    final p = _proposal!;
    final t = widget.track;
    final l = context.l10n;
    final m = p.meta;
    String? differs(String? cur, String? next) =>
        (next == null || next == cur) ? null : next;
    return [
      if (differs(t.title, m?.title) != null)
        _Row(EnrichField.title, l.fieldTitle, t.title, m!.title),
      if (differs(t.artist, m?.artist) != null)
        _Row(EnrichField.artist, l.fieldArtist, t.artist, m!.artist),
      if (differs(t.album, m?.album) != null)
        _Row(EnrichField.album, l.fieldAlbum, t.album, m!.album),
      if (m?.year != null && m!.year != t.year)
        _Row(EnrichField.year, l.fieldYear, '${t.year ?? ''}', '${m.year}'),
      if (differs(t.genre, m?.genre) != null)
        _Row(EnrichField.genre, l.fieldGenre, t.genre, m!.genre),
      if (m?.trackNumber != null && m!.trackNumber != t.trackNumber)
        _Row(EnrichField.trackNumber, l.fieldTrackNumber,
            '${t.trackNumber ?? ''}', '${m.trackNumber}'),
      if (m?.artworkUrl != null)
        _Row(EnrichField.cover, l.fieldCover, null, m!.artworkUrl),
      if (p.lyrics != null && !p.lyrics!.isEmpty)
        _Row(EnrichField.lyrics, l.fieldLyrics, null,
            (p.lyrics!.plain ?? p.lyrics!.synced ?? '')),
      if (p.curiosity != null)
        _Row(EnrichField.curiosity, l.fieldCuriosity, null, p.curiosity!.text),
    ];
  }

  bool _locked(_Row r) =>
      widget.track.userEdited &&
      const {EnrichField.title, EnrichField.artist, EnrichField.album}
          .contains(r.field);

  Future<void> _apply() async {
    await ref
        .read(enrichmentServiceProvider)
        .apply(_proposal!, _selected, replaceCover: true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget body;
    if (_loading) {
      body = const SizedBox(
          height: 80, child: Center(child: CircularProgressIndicator()));
    } else if (_rateLimited) {
      body = Text(l.serviceUnavailable);
    } else {
      final rows = _rows(context);
      body = rows.isEmpty
          ? Text(l.nothingFound)
          : SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final r in rows)
                  CheckboxListTile(
                    dense: true,
                    value: _selected.contains(r.field),
                    onChanged: _locked(r)
                        ? null
                        : (v) => setState(() => v == true
                            ? _selected.add(r.field)
                            : _selected.remove(r.field)),
                    title: Text(r.label),
                    subtitle: r.field == EnrichField.cover
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Image.network(r.proposed!,
                                width: 72,
                                height: 72,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.image_not_supported)),
                          )
                        : Text(
                            _locked(r)
                                ? l.userEditedLocked
                                : '${l.currentValue}: ${r.current ?? '—'}\n'
                                    '${l.proposedValue}: ${r.proposed}',
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis),
                  ),
              ]),
            );
    }
    return AlertDialog(
      title: Text(l.enrichPreviewTitle),
      content: SizedBox(width: 420, child: body),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel)),
        FilledButton(
            onPressed: _selected.isEmpty ? null : _apply,
            child: Text(l.apply)),
      ],
    );
  }
}
