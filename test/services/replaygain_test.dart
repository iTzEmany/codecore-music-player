import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/tags/tag_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseReplayGain', () {
    expect(parseReplayGain('-6.50 dB'), -6.5);
    expect(parseReplayGain('+1.2dB'), 1.2);
    expect(parseReplayGain('-3'), -3);
    expect(parseReplayGain('-4,25 dB'), -4.25);
    expect(parseReplayGain('loud'), isNull);
    expect(parseReplayGain(null), isNull);
  });

  test('gain factor never boosts above 1', () {
    expect(CodecoreAudioHandler.gainFactor(null), 1.0);
    expect(CodecoreAudioHandler.gainFactor(3.0), 1.0);
    expect(CodecoreAudioHandler.gainFactor(-6.0), closeTo(0.501, 0.01));
    expect(CodecoreAudioHandler.gainFactor(-20.0), closeTo(0.1, 0.001));
  });

  test('normalizeIsrc uppercases and strips dashes and spaces', () {
    expect(normalizeIsrc(' it-abc 12-34567 '), 'ITABC1234567');
    expect(normalizeIsrc(' - '), isNull);
    expect(normalizeIsrc(null), isNull);
  });
}
