import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:smtc_windows/smtc_windows.dart';

import '../../core/app_log.dart';
import 'codecore_audio_handler.dart';
import 'system_media_controls.dart';

/// The SMTC status of the player.
PlaybackStatus smtcStatus({required bool hasTrack, required bool playing}) =>
    !hasTrack ? PlaybackStatus.stopped : (playing ? PlaybackStatus.playing : PlaybackStatus.paused);

MusicMetadata smtcMetadata(MediaItem? item) => item == null
    ? const MusicMetadata()
    : MusicMetadata(
        title: item.title,
        artist: item.artist,
        album: item.album,
        thumbnail: item.artUri?.toString(),
      );

PlaybackTimeline smtcTimeline(Duration position, Duration? length) => PlaybackTimeline(
      startTimeMs: 0,
      endTimeMs: (length ?? Duration.zero).inMilliseconds,
      positionMs: position.inMilliseconds,
    );

/// Windows' media overlay (volume flyout, lock screen) and media keys, even
/// with the window minimised. Needs `SMTCWindows.initialize()` once at start.
class SmtcControls implements SystemMediaControls {
  SMTCWindows? _smtc;
  final _subs = <StreamSubscription<Object?>>[];

  @override
  Future<void> attach(CodecoreAudioHandler handler) async {
    try {
      await SMTCWindows.initialize();
      final smtc = SMTCWindows();
      _smtc = smtc;
      MediaItem? item;
      var playing = false;
      Duration position = Duration.zero;
      void status() => smtc.setPlaybackStatus(smtcStatus(hasTrack: item != null, playing: playing));
      _subs
        ..add(smtc.buttonPressStream.listen((b) {
          switch (b) {
            case PressedButton.play:
              unawaited(handler.play());
            case PressedButton.pause:
              unawaited(handler.pause());
            case PressedButton.next:
              unawaited(handler.skipToNext());
            case PressedButton.previous:
              unawaited(handler.skipToPrevious());
            case PressedButton.stop:
              unawaited(handler.stop());
            default:
              break;
          }
        }))
        ..add(handler.mediaItem.listen((i) {
          item = i;
          smtc.updateMetadata(smtcMetadata(i));
          smtc.updateTimeline(smtcTimeline(position, i?.duration));
          status();
        }))
        ..add(handler.playbackState.listen((s) {
          if (s.playing != playing) {
            playing = s.playing;
            status();
          }
        }))
        ..add(handler.positionStream
            .where((p) => (p - position).abs() >= const Duration(seconds: 1))
            .listen((p) {
          position = p;
          smtc.updateTimeline(smtcTimeline(p, item?.duration));
        }));
      AppLog.i('smtc: attached');
    } on Object catch (e, st) {
      AppLog.w('smtc unavailable', e, st);
      await dispose();
    }
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _smtc?.dispose();
    _smtc = null;
  }
}
