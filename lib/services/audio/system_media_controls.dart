import 'codecore_audio_handler.dart';

/// The operating system's own media controls (MPRIS on Linux, SMTC on
/// Windows): what shows the track outside the app and takes the media keys.
abstract class SystemMediaControls {
  /// Starts mirroring [handler] and obeying the system's commands.
  Future<void> attach(CodecoreAudioHandler handler);

  Future<void> dispose();
}

/// Where there is nothing to attach to.
class NoSystemMediaControls implements SystemMediaControls {
  const NoSystemMediaControls();

  @override
  Future<void> attach(CodecoreAudioHandler handler) async {}

  @override
  Future<void> dispose() async {}
}
