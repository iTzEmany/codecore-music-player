import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/permissions.dart';
import '../../data/db/app_database.dart';
import '../../providers/database_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/player_providers.dart';
import '../strings_it.dart';
import 'debug_player_bar.dart';

class DebugLibraryScreen extends ConsumerStatefulWidget {
  const DebugLibraryScreen({super.key});

  @override
  ConsumerState<DebugLibraryScreen> createState() => _DebugLibraryScreenState();
}

class _DebugLibraryScreenState extends ConsumerState<DebugLibraryScreen> {
  bool _denied = false;
  StreamSubscription<String>? _errors;

  @override
  void initState() {
    super.initState();
    _errors = ref.read(playerErrorsProvider).listen((m) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(m)));
    });
  }

  @override
  void dispose() {
    _errors?.cancel();
    super.dispose();
  }

  Future<void> _pick() async {
    final path = await FilePicker.getDirectoryPath();
    if (path == null || !mounted) return;
    await ref.read(folderRepositoryProvider).add(path);
  }

  Future<void> _scan() async {
    final ok = await ensureAudioPermission();
    if (!mounted) return;
    setState(() => _denied = !ok);
    if (!ok) return;
    await ref.read(scanStateProvider.notifier).scanAll();
  }

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(tracksProvider);
    final scan = ref.watch(scanStateProvider);
    final folders = ref.watch(foldersProvider).value ?? const [];
    final progress = scan.progress;
    return Scaffold(
      appBar: AppBar(title: const Text(S.appName)),
      bottomNavigationBar: const DebugPlayerBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(spacing: 8, children: [
              FilledButton(onPressed: _pick, child: const Text(S.chooseFolder)),
              FilledButton.tonal(
                  onPressed: scan.running ? null : _scan,
                  child: const Text(S.scan)),
              if (_denied)
                TextButton(
                    onPressed: openAppSettings,
                    child: const Text(S.openSettings)),
            ]),
          ),
          for (final f in folders)
            Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(f.path, overflow: TextOverflow.ellipsis))),
          if (scan.running)
            LinearProgressIndicator(
              value: (progress == null || progress.total == 0)
                  ? null
                  : progress.done / progress.total,
            ),
          if (scan.error != null)
            Padding(
                padding: const EdgeInsets.all(8),
                child: Text(scan.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error))),
          Expanded(
            child: tracks.when(
              data: (list) => list.isEmpty
                  ? const Center(child: Text(S.noTracks))
                  : Column(children: [
                      Text('${list.length} brani'),
                      Expanded(child: _TrackList(list: list)),
                    ]),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackList extends ConsumerWidget {
  const _TrackList({required this.list});

  final List<Track> list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final covers = ref.watch(coversDirProvider).value;
    return ListView.builder(
      itemExtent: 56,
      itemCount: list.length,
      itemBuilder: (context, i) {
        final t = list[i];
        File? cover;
        if (t.hasCover && t.coverKey != null && covers != null) {
          final f = File('${covers.path}/${t.coverKey}.jpg');
          final g = File('${covers.path}/${t.coverKey}.png');
          cover = f.existsSync() ? f : (g.existsSync() ? g : null);
        }
        return ListTile(
          leading: SizedBox(
            width: 48,
            height: 48,
            child: cover == null
                ? const Icon(Icons.music_note)
                : Image.file(cover, cacheWidth: 96, fit: BoxFit.cover),
          ),
          title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(t.artist ?? '', maxLines: 1),
          onTap: () =>
              ref.read(playerControllerProvider).playFromList(list, i),
        );
      },
    );
  }
}
