import 'package:codecore/services/audio/just_audio_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  test('a refused stream is told by the status or by ExoPlayer\'s «Source error»', () {
    expect(streamLooksExpired(Exception('Response code: 403')), isTrue);
    expect(streamLooksExpired(Exception('status 410 Gone')), isTrue);
    expect(streamLooksExpired(PlayerException(0, 'Source error', null)), isTrue);
    expect(streamLooksExpired(PlayerException(1, 'Renderer error', null)), isFalse);
    expect(streamLooksExpired(Exception('boom')), isFalse);
  });
}
