import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../widgets/cover_image.dart';

/// Multi-select over the whole library; pops with the chosen ids.
class TrackPickerScreen extends ConsumerStatefulWidget {
  const TrackPickerScreen({super.key, this.initial = const {}});

  final Set<int> initial;

  @override
  ConsumerState<TrackPickerScreen> createState() => _State();
}

class _State extends ConsumerState<TrackPickerScreen> {
  late final Set<int> _selected = {...widget.initial};
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.sharePick),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: Text(l.save),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              onChanged: (t) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 250), () {
                  if (mounted) setState(() => _query = t);
                });
              },
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
              stream: ref
                  .watch(trackRepositoryProvider)
                  .watchTracks(query: _query),
              builder: (context, snap) {
                final tracks = snap.data ?? const <Track>[];
                return ListView.builder(
                  itemExtent: 64,
                  itemCount: tracks.length,
                  itemBuilder: (_, i) {
                    final t = tracks[i];
                    return CheckboxListTile(
                      value: _selected.contains(t.id),
                      onChanged: (v) => setState(
                        () => v == true
                            ? _selected.add(t.id)
                            : _selected.remove(t.id),
                      ),
                      secondary: CoverImage(coverKey: t.coverKey, size: 44),
                      title: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        t.artist ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
