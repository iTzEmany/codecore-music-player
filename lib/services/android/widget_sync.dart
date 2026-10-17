// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import '../../data/db/app_database.dart';
import 'widget_bridge.dart';

/// Keeps a [WidgetBridge] up to date with the player: one write when the
/// track or the play state changes, none otherwise (never on a position tick,
/// so the widget costs no battery).
class WidgetSync {
  WidgetSync({
    required Stream<Track?> tracks,
    required Stream<bool> playing,
    required WidgetBridge bridge,
    required String? Function(Track) coverPath,
    Track? initialTrack,
    bool initialPlaying = false,
  })  : _bridge = bridge,
        _coverPath = coverPath,
        _track = initialTrack,
        _playing = initialPlaying {
    _subs = [
      tracks.listen((t) {
        _track = t;
        _push();
      }),
      playing.listen((p) {
        _playing = p;
        _push();
      }),
    ];
    _push();
  }

  final WidgetBridge _bridge;
  final String? Function(Track) _coverPath;
  late final List<StreamSubscription<Object?>> _subs;
  Track? _track;
  bool _playing;
  WidgetSnapshot? _last;

  void _push() {
    final t = _track;
    final next = t == null
        ? WidgetSnapshot.empty
        : WidgetSnapshot(
            title: t.title,
            artist: t.artist,
            coverPath: _coverPath(t),
            playing: _playing,
          );
    if (next == _last) return;
    _last = next;
    unawaited(_bridge.update(next));
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
  }
}
