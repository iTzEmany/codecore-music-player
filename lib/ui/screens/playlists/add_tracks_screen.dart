import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/track_row.dart';

/// Pick saved tracks to put into a playlist: rows with a ＋ / ✓ circle and a
/// fixed «Aggiungi N brani» bar at the bottom.
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
      for (final t
          in ref.watch(playlistTracksProvider(widget.playlistId)).value ??
              const <Track>[])
        t.id,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l.addSongs)),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(CcDims.margin),
                child: FilledButton(
                  onPressed: _add,
                  child: Text(l.addNSongs(_selected.length)),
                ),
              ),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  CcDims.margin,
                  4,
                  CcDims.margin,
                  8,
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: l.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Track>>(
                  stream: ref
                      .watch(trackRepositoryProvider)
                      .watchTracks(query: _query),
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
                            : l.noResults,
                      );
                    }
                    return ListView.builder(
                      itemExtent: 64,
                      itemCount: tracks.length,
                      itemBuilder: (_, i) {
                        final t = tracks[i];
                        return TrackRow(
                          track: t,
                          variant: TrackRowVariant.pick,
                          picked: _selected.contains(t.id),
                          onTap: () => setState(
                            () => _selected.contains(t.id)
                                ? _selected.remove(t.id)
                                : _selected.add(t.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
