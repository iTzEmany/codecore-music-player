import 'package:dbus/dbus.dart';

import 'play_queue.dart';

/// The MPRIS `PlaybackStatus` of the player.
String mprisStatus({required bool hasTrack, required bool playing}) =>
    !hasTrack ? 'Stopped' : (playing ? 'Playing' : 'Paused');

/// `/org/codecore/track/<id>`: the object path that names a track.
DBusObjectPath mprisTrackId(String mediaId) =>
    DBusObjectPath('/org/codecore/track/${mediaId.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')}');

/// The `Metadata` map for a track. [artUri] must already be a `file://` URI;
/// the length goes in microseconds.
Map<String, DBusValue> mprisMetadata({
  required String? mediaId,
  String? title,
  String? artist,
  String? album,
  Duration? duration,
  Uri? artUri,
}) {
  if (mediaId == null) return {'mpris:trackid': mprisTrackId('none')};
  return {
    'mpris:trackid': mprisTrackId(mediaId),
    if (duration != null && duration > Duration.zero) 'mpris:length': DBusInt64(duration.inMicroseconds),
    if (artUri != null) 'mpris:artUrl': DBusString(artUri.toString()),
    if (title != null) 'xesam:title': DBusString(title),
    if (artist != null && artist.isNotEmpty) 'xesam:artist': DBusArray.string([artist]),
    if (album != null && album.isNotEmpty) 'xesam:album': DBusString(album),
  };
}

/// `Seek(offset)` and `SetPosition(trackid, position)` as a target position,
/// clamped to the track; null when the request does not apply.
Duration? mprisSeekTarget({
  required Duration current,
  required Duration? length,
  int? offsetMicros,
  int? positionMicros,
  DBusObjectPath? trackId,
  DBusObjectPath? currentTrackId,
}) {
  Duration? target;
  if (offsetMicros != null) {
    target = current + Duration(microseconds: offsetMicros);
  } else if (positionMicros != null) {
    if (trackId != null && trackId != currentTrackId) return null; // another track
    target = Duration(microseconds: positionMicros);
  }
  if (target == null) return null;
  if (target < Duration.zero) target = Duration.zero;
  if (length != null && length > Duration.zero && target > length) return null; // past the end: ignored
  return target;
}

/// MPRIS `LoopStatus` for the handler's repeat mode.
String mprisLoopStatus(PlayRepeat r) => switch (r) {
  PlayRepeat.off => 'None',
  PlayRepeat.one => 'Track',
  PlayRepeat.all => 'Playlist',
};

/// The repeat mode a client asked for; null for an unknown value.
PlayRepeat? mprisRepeatFromLoop(String v) => switch (v) {
  'None' => PlayRepeat.off,
  'Track' => PlayRepeat.one,
  'Playlist' => PlayRepeat.all,
  _ => null,
};
