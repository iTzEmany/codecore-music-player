import 'dart:async';
import 'dart:io';

import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/stream/stream_preparer.dart';

/// A [StreamPreparer] with no network: `ready` writes a tiny file, makes the
/// shadow row like the real one and can be held back or made to fail per key.
class FakeStreamPreparer implements StreamPreparer {
  FakeStreamPreparer(this.tracks, this.dir);

  @override
  final TrackRepository tracks;
  final Directory dir;
  final queues = <List<String>>[];
  final asked = <String>[];
  final failing = <String>{};
  Object failure = StateError('download failed'); // what a failing key throws
  final gates = <String, Completer<void>>{};

  @override
  void setQueue(List<StreamItem> items) => queues.add([for (final i in items) i.key]);

  @override
  Future<File> ready(String key, YtResult r) async {
    asked.add(key);
    final gate = gates[key];
    if (gate != null) await gate.future;
    if (failing.contains(key)) throw failure;
    final file = File('${dir.path}/${key.replaceAll(':', '_')}.m4a')..writeAsStringSync('x');
    await tracks.upsertStreamRow(key, r, file);
    return file;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
