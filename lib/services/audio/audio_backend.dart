enum BackendState { idle, loading, ready, playing, paused, completed, error }

class BackendException implements Exception {
  const BackendException(this.message, {this.fileMissing = false});

  final String message;
  final bool fileMissing;

  @override
  String toString() => 'BackendException: $message';
}

abstract class AudioBackend {
  Stream<Duration> get position;
  Stream<Duration?> get duration;
  Stream<BackendState> get state;

  /// Throws [BackendException] when the file cannot be played.
  Future<void> load(String filePath);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> dispose();
}
