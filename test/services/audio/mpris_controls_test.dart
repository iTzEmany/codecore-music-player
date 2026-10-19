import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/mpris_controls.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:dbus/dbus.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_backend.dart';

/// Needs a session bus (a desktop session); skipped without one.
final _hasBus = Platform.isLinux && (Platform.environment['DBUS_SESSION_BUS_ADDRESS'] ?? '').isNotEmpty;

void main() {
  test('on the real session bus: metadata, status and commands round-trip', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = TrackRepository(db);
    for (var i = 0; i < 2; i++) {
      await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/m/$i.mp3', title: 'Song $i', albumKey: 'k', format: 'mp3', sizeBytes: 1, mtimeMs: 1, addedAt: 1,
          artist: const Value('Band'), album: const Value('Alb'), durationMs: const Value(120000)));
    }
    final handler = CodecoreAudioHandler(FakeBackend(), PlayQueue(), repo, onError: (_) {});
    addTearDown(handler.dispose);
    final controls = MprisControls();
    await controls.attach(handler);
    addTearDown(controls.dispose);

    final client = DBusClient.session();
    addTearDown(client.close);
    final player = DBusRemoteObject(client,
        name: 'org.mpris.MediaPlayer2.codecore', path: DBusObjectPath('/org/mpris/MediaPlayer2'));
    Future<DBusValue> prop(String n) => player.getProperty('org.mpris.MediaPlayer2.Player', n);

    expect((await prop('PlaybackStatus') as DBusString).value, 'Stopped');
    await handler.playQueue([1, 2], 0);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect((await prop('PlaybackStatus') as DBusString).value, 'Playing');
    final meta = (await prop('Metadata') as DBusDict).children;
    final byKey = {for (final e in meta.entries) (e.key as DBusString).value: (e.value as DBusVariant).value};
    expect((byKey['xesam:title'] as DBusString).value, 'Song 0');
    expect((byKey['mpris:length'] as DBusInt64).value, 120000000);

    await player.callMethod('org.mpris.MediaPlayer2.Player', 'Pause', [], replySignature: DBusSignature(''));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect((await prop('PlaybackStatus') as DBusString).value, 'Paused');
    await player.callMethod('org.mpris.MediaPlayer2.Player', 'Next', [], replySignature: DBusSignature(''));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(handler.currentTrack!.title, 'Song 1');
    expect((await player.getProperty('org.mpris.MediaPlayer2', 'Identity') as DBusString).value, 'Codecore');
  }, skip: _hasBus ? false : 'no D-Bus session bus');
}
