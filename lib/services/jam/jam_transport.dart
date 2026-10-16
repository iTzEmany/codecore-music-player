import 'dart:async';

import '../audio/remote_transport.dart';
import 'jam_models.dart';

/// The Jam seen as a [RemoteTransport]: its state becomes the notification, and
/// the buttons become Jam commands (so the Jam's own rules apply: a guest
/// cannot skip).
class JamTransport implements RemoteTransport {
  JamTransport({
    required this.send,
    required this.canSkip,
    required this.nowMs,
  });

  final Future<Object?> Function(JamCommand cmd) send;
  final bool canSkip;

  /// The Jam's reference clock (the host's).
  final int Function() nowMs;

  final _changes = StreamController<RemoteStatus>.broadcast();
  JamState? _state;

  void update(JamState s) {
    _state = s;
    if (!_changes.isClosed) _changes.add(status);
  }

  @override
  Stream<RemoteStatus> get changes => _changes.stream;

  @override
  RemoteStatus get status {
    final s = _state;
    final item = s?.current;
    if (s == null || item == null) return RemoteStatus(canSkip: canSkip);
    final duration = item.durationMs > 0 ? Duration(milliseconds: item.durationMs) : null;
    var ms = s.positionMs + (s.playing ? nowMs() - s.positionAt : 0);
    if (ms < 0) ms = 0;
    if (duration != null && ms > duration.inMilliseconds) ms = duration.inMilliseconds;
    return RemoteStatus(
      title: item.title,
      artist: item.artist,
      album: item.album,
      duration: duration,
      position: Duration(milliseconds: ms),
      playing: s.playing,
      canSkip: canSkip,
    );
  }

  @override
  Future<void> play() => send(const JamCommand.play());

  @override
  Future<void> pause() => send(const JamCommand.pause());

  @override
  Future<void> next() async {
    if (canSkip) await send(const JamCommand.next());
  }

  @override
  Future<void> seek(Duration position) =>
      send(JamCommand.seek(position.inMilliseconds));

  Future<void> dispose() => _changes.close();
}
