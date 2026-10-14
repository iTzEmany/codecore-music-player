import 'dart:async';

import 'package:codecore/services/audio/audio_backend.dart';

class FakeBackend implements AudioBackend {
  final stateC = StreamController<BackendState>.broadcast();
  final posC = StreamController<Duration>.broadcast();
  final durC = StreamController<Duration?>.broadcast();
  final loaded = <String>[];
  final failing = <String>{};
  bool playing = false;

  @override
  Stream<BackendState> get state => stateC.stream;
  @override
  Stream<Duration> get position => posC.stream;
  @override
  Stream<Duration?> get duration => durC.stream;

  @override
  Future<void> load(String filePath) async {
    if (failing.contains(filePath)) throw const BackendException('missing', fileMissing: true);
    loaded.add(filePath);
    stateC.add(BackendState.paused);
  }

  @override
  Future<void> play() async {
    playing = true;
    stateC.add(BackendState.playing);
  }

  @override
  Future<void> pause() async {
    playing = false;
    stateC.add(BackendState.paused);
  }

  @override
  Future<void> stop() async {
    playing = false;
    stateC.add(BackendState.idle);
  }

  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> dispose() async {}
}
