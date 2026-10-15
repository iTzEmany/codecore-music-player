import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/library_providers.dart';
import '../../widgets/empty_state.dart';

class MissingTracksScreen extends ConsumerStatefulWidget {
  const MissingTracksScreen({super.key});

  @override
  ConsumerState<MissingTracksScreen> createState() =>
      _MissingTracksScreenState();
}

class _MissingTracksScreenState extends ConsumerState<MissingTracksScreen> {
  final _ignored = <int>{};

  Future<void> _confirmRemove(int id) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.confirmRemoveTitle),
        content: Text(l.confirmRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(l.removeFromLibrary),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(trackRepositoryProvider).deleteTrack(id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = (ref.watch(missingTracksProvider).value ?? const [])
        .where((t) => !_ignored.contains(t.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(l.missingTracksTitle)),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.check_circle_outline,
              message: l.noMissingTracks,
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final t = items[i];
                return ListTile(
                  title: Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    t.path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Wrap(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _ignored.add(t.id)),
                        child: Text(l.ignore),
                      ),
                      TextButton(
                        onPressed: () => _confirmRemove(t.id),
                        child: Text(l.removeFromLibrary),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
