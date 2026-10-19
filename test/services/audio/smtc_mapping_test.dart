import 'package:audio_service/audio_service.dart';
import 'package:codecore/services/audio/smtc_controls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smtc_windows/smtc_windows.dart';

void main() {
  test('status follows track and play state', () {
    expect(smtcStatus(hasTrack: false, playing: true), PlaybackStatus.stopped);
    expect(smtcStatus(hasTrack: true, playing: true), PlaybackStatus.playing);
    expect(smtcStatus(hasTrack: true, playing: false), PlaybackStatus.paused);
  });

  test('metadata carries title, artist, album and the cover as a URI; nothing for no track', () {
    final m = smtcMetadata(MediaItem(id: '1', title: 'Song', artist: 'Band', album: 'Alb', artUri: Uri.file('/c/a.jpg')));
    expect((m.title, m.artist, m.album, m.thumbnail), ('Song', 'Band', 'Alb', 'file:///c/a.jpg'));
    expect(smtcMetadata(null).title, isNull);
  });

  test('timeline in milliseconds; unknown length is 0', () {
    final t = smtcTimeline(const Duration(seconds: 12), const Duration(minutes: 3));
    expect((t.positionMs, t.endTimeMs, t.startTimeMs), (12000, 180000, 0));
    expect(smtcTimeline(Duration.zero, null).endTimeMs, 0);
  });
}
