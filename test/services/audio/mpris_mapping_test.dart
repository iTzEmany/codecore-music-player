import 'package:codecore/services/audio/mpris_mapping.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('status: no track is Stopped, else Playing or Paused', () {
    expect(mprisStatus(hasTrack: false, playing: true), 'Stopped');
    expect(mprisStatus(hasTrack: true, playing: true), 'Playing');
    expect(mprisStatus(hasTrack: true, playing: false), 'Paused');
  });

  test('track ids are valid object paths whatever the media id', () {
    expect(mprisTrackId('42').value, '/org/codecore/track/42');
    expect(mprisTrackId('track:7@album:a b').value, '/org/codecore/track/track_7_album_a_b');
  });

  test('metadata: microseconds, file:// art, artist as a list, empty fields left out', () {
    final m = mprisMetadata(
      mediaId: '5', title: 'Song', artist: 'Band', album: 'Alb',
      duration: const Duration(seconds: 200), artUri: Uri.file('/covers/a.jpg'),
    );
    expect((m['mpris:length'] as DBusInt64).value, 200000000);
    expect((m['mpris:artUrl'] as DBusString).value, 'file:///covers/a.jpg');
    expect((m['xesam:title'] as DBusString).value, 'Song');
    expect((m['xesam:artist'] as DBusArray).children.map((c) => (c as DBusString).value), ['Band']);
    expect((m['xesam:album'] as DBusString).value, 'Alb');

    final bare = mprisMetadata(mediaId: '5', title: 'Only', artist: '', duration: Duration.zero);
    expect(bare.keys.toSet(), {'mpris:trackid', 'xesam:title'});
    expect(mprisMetadata(mediaId: null).keys, ['mpris:trackid']);
  });

  test('seek: relative, absolute for the current track only, clamped at 0, ignored past the end', () {
    const len = Duration(seconds: 100);
    final here = mprisTrackId('1');
    expect(mprisSeekTarget(current: const Duration(seconds: 10), length: len, offsetMicros: 5000000), const Duration(seconds: 15));
    expect(mprisSeekTarget(current: const Duration(seconds: 3), length: len, offsetMicros: -9000000), Duration.zero);
    expect(mprisSeekTarget(current: const Duration(seconds: 3), length: len, offsetMicros: 999000000), isNull);
    expect(mprisSeekTarget(current: Duration.zero, length: len, positionMicros: 40000000, trackId: here, currentTrackId: here), const Duration(seconds: 40));
    expect(mprisSeekTarget(current: Duration.zero, length: len, positionMicros: 40000000, trackId: mprisTrackId('2'), currentTrackId: here), isNull);
    expect(mprisSeekTarget(current: Duration.zero, length: len), isNull);
  });
}
