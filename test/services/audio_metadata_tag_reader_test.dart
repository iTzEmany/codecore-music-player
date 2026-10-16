import 'package:codecore/services/tags/audio_metadata_tag_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reader = AudioMetadataTagReader();

  test('reads mp3 tags', () async {
    final t = await reader.read('test/fixtures/sample.mp3');
    expect(t.title, 'Fixture Song');
    expect(t.artist, 'Fixture Artist');
    expect(t.album, 'Fixture Album');
    expect(t.trackNumber, 3);
    expect(t.durationMs, inInclusiveRange(1500, 2600));
  });

  test('reads flac tags', () async {
    final t = await reader.read('test/fixtures/sample.flac');
    expect(t.title, 'Flac Song');
    expect(t.artist, 'Flac Artist');
    expect(t.durationMs, isNotNull);
  });

  test('missing file returns empty info', () async {
    final t = await reader.read('test/fixtures/nope.mp3');
    expect(t.title, isNull);
  });

  test('reads ReplayGain from FLAC (and not from files without it)', () async {
    final rg = await reader.read('test/fixtures/replaygain.flac');
    expect(rg.replayGainDb, -6.5);
    final plain = await reader.read('test/fixtures/sample.flac');
    expect(plain.replayGainDb, isNull);
  });

  test('reads ReplayGain from an ID3 TXXX frame', () async {
    final rg = await reader.read('test/fixtures/replaygain.mp3');
    expect(rg.replayGainDb, -4.0);
  });

  test('reads the duration of an untagged m4a as downloaded without re-encoding',
      () async {
    final t = await reader.read('test/fixtures/original.m4a');
    expect(t.durationMs, inInclusiveRange(2500, 3500));
  });
}
