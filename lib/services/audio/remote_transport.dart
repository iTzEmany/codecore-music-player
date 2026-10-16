/// What the system media controls (notification, lock screen, headset buttons)
/// show while something other than the local player is playing: today, a Jam.
class RemoteStatus {
  const RemoteStatus({
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.position = Duration.zero,
    this.playing = false,
    this.canSkip = false,
  });

  /// Null title = nothing to show (an empty queue).
  final String? title, artist, album;
  final Duration? duration;
  final Duration position;
  final bool playing;

  /// «Next» is offered (in a Jam only the host can skip).
  final bool canSkip;

  bool get hasItem => title != null;
}

/// A player the handler forwards the system controls to. While one is attached
/// the local queue and backend are left alone.
abstract class RemoteTransport {
  RemoteStatus get status;
  Stream<RemoteStatus> get changes;

  Future<void> play();
  Future<void> pause();
  Future<void> next();
  Future<void> seek(Duration position);
}
