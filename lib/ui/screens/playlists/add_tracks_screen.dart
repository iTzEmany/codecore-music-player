import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/empty_state.dart';

/// Pick saved tracks to put into a playlist (opened by the "+" button).
class AddTracksScreen extends ConsumerStatefulWidget {
  const AddTracksScreen({super.key, required this.playlistId});

  final int playlistId;

  @override
  ConsumerState<AddTracksScreen> createState() => _AddTracksScreenState();
}

class _AddTracksScreenState extends ConsumerState<AddTracksScreen> {
  final _selected = <int>{};
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = text);
    });
  }

  Future<void> _add() async {
    await ref
        .read(playlistRepositoryProvider)
        .addTracks(widget.playlistId, _selected.toList());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final inPlaylist = {
      for (final t in ref.watch(playlistTracksProvider(widget.playlistId)).value ??
          const <Track>[])
        t.id,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(l.addSongs),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : _add,
            child: Text(l.addNSongs(_selected.length)),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _controller,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: l.searchHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Track>>(
            stream: ref.watch(trackRepositoryProvider).watchTracks(query: _query),
            builder: (context, snap) {
              final tracks = [
                for (final t in snap.data ?? const <Track>[])
                  if (!inPlaylist.contains(t.id)) t,
              ];
              if (snap.hasData && tracks.isEmpty) {
                return EmptyState(
                    icon: Icons.library_music,
                    message: _query.isEmpty
                        ? l.allSongsInPlaylist
                        : l.noResults);
              }
              return ListView.builder(
                itemExtent: 64,
                itemCount: tracks.length,
                itemBuilder: (_, i) {
                  final t = tracks[i];
                  return CheckboxListTile(
                    value: _selected.contains(t.id),
                    onChanged: (v) => setState(() =>
                        v == true ? _selected.add(t.id) : _selected.remove(t.id)),
                    secondary: CoverImage(coverKey: t.coverKey, size: 44),
                    title: Text(t.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        [if (t.artist != null) t.artist!, if (t.album != null) t.album!]
                            .join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
