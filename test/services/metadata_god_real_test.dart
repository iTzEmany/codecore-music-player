@TestOn('linux')
library;

import 'dart:io';

import 'package:codecore/services/tags/audio_metadata_tag_reader.dart';
import 'package:codecore/services/tags/metadata_god_tag_writer.dart';
import 'package:codecore/services/tags/safe_tag_writer.dart';
import 'package:codecore/services/tags/tag_backups.dart';
import 'package:codecore/services/tags/tag_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Real files through the real Rust library. It only runs where the library
/// can be loaded: build once (`flutter build linux --debug`) and run
///   LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib flutter test this file
/// otherwise every test is skipped.
Future<String?> _audioMd5(String path) async {
  final r = await Process.run('ffmpeg', [
    '-v', 'error', '-i', path, '-map', '0:a', '-f', 'md5', '-',
  ]);
  return r.exitCode == 0 ? r.stdout.toString().trim() : null;
}

/// The tags exactly as another program (ffprobe) sees them, keys lower-case.
Future<Map<String, String>> _probeTags(String path) async {
  final r = await Process.run('ffprobe', [
    '-v', 'error', '-show_entries', 'format_tags', '-of', 'default=nw=1', path,
  ]);
  return {
    for (final l in r.stdout.toString().split('\n'))
      if (l.startsWith('TAG:') && l.contains('='))
        l.substring(4, l.indexOf('=')).toLowerCase(): l.substring(l.indexOf('=') + 1),
  };
}

void main() {
  late Directory root;
  final writer = MetadataGodTagWriter();
  String? skip;

  setUpAll(() async {
    final probe = Directory.systemTemp.createTempSync('mgprobe');
    final f = File(p.join(probe.path, 'a.mp3'))
      ..writeAsBytesSync(File('test/fixtures/sample.mp3').readAsBytesSync());
    try {
      await writer.write(f.path, const TagChanges(title: 'probe'));
    } on TagWriteException catch (e) {
      skip = 'metadata_god library not loadable: ${e.detail}';
    } finally {
      probe.deleteSync(recursive: true);
    }
  });

  setUp(() => root = Directory.systemTemp.createTempSync('mgreal'));
  tearDown(() => root.deleteSync(recursive: true));

  for (final fixture in ['sample.mp3', 'sample.flac', 'original.m4a']) {
    test('$fixture: new tags, audio stream identical, backup restores the original', () async {
      if (skip != null) {
        markTestSkipped(skip!);
        return;
      }
      final song = p.join(root.path, fixture);
      File('test/fixtures/$fixture').copySync(song);
      final audioBefore = await _audioMd5(song);
      final bytesBefore = File(song).readAsBytesSync();
      const reader = AudioMetadataTagReader();
      final coverBefore = (await reader.read(song)).coverBytes?.length;

      final safe = SafeTagWriter(
        writer: writer,
        reader: reader,
        workDir: Directory(p.join(root.path, 'work')),
        backups: TagBackupStore(Directory(p.join(root.path, 'bk'))),
      );
      final stamp = await safe.write(
        song,
        const TagChanges(
          title: 'Città vecchia',
          artist: 'Fabrizio',
          album: 'Album Nuovo',
          albumArtist: 'Fabrizio',
          year: 1999,
          trackNumber: 3,
        ),
      );

      final after = await reader.read(song);
      expect(after.title, 'Città vecchia');
      expect(after.artist, 'Fabrizio');
      expect(after.album, 'Album Nuovo');
      expect(after.trackNumber, 3);
      final seen = await _probeTags(song);
      expect(seen['title'], 'Città vecchia');
      expect(seen['album_artist'], 'Fabrizio');
      expect(seen['artist'], 'Fabrizio');
      expect(seen['date'] ?? seen['year'], '1999');
      expect(after.coverBytes?.length, coverBefore);
      expect(await _audioMd5(song), audioBefore, reason: 'audio untouched');
      expect(stamp.sizeBytes, File(song).lengthSync());
      expect(Directory(p.join(root.path, 'work')).listSync(), isEmpty);

      final store = TagBackupStore(Directory(p.join(root.path, 'bk')));
      final list = await store.list();
      expect(list, hasLength(1));
      await store.restore(list.single);
      expect(File(song).readAsBytesSync(), bytesBefore);
    });
  }

  // Files without a cover, as downloads are: disc number + cover go in once.
  for (final fixture in ['original.m4a', 'sample.mp3']) {
    test('$fixture: disc and cover are written once, a second pass adds no picture', () async {
      if (skip != null) {
        markTestSkipped(skip!);
        return;
      }
      final song = p.join(root.path, fixture);
      File('test/fixtures/$fixture').copySync(song);
      const reader = AudioMetadataTagReader();
      final before = await reader.read(song);
      if (before.coverBytes?.isNotEmpty ?? false) {
        markTestSkipped('fixture already has a cover');
        return;
      }
      final safe = SafeTagWriter(
        writer: writer,
        reader: reader,
        workDir: Directory(p.join(root.path, 'work')),
        backups: TagBackupStore(Directory(p.join(root.path, 'bk'))),
      );
      // A minimal JPEG: SOI, JFIF header, EOI.
      final jpeg = [
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9,
      ];
      await safe.write(
        song,
        TagChanges(discNumber: 2, cover: TagCover(jpeg, 'image/jpeg')),
        backup: false,
      );
      final once = await reader.read(song);
      expect(once.discNumber, 2);
      expect(once.coverBytes, isNotEmpty);
      expect(once.durationMs, closeTo(before.durationMs!, 100));

      // The tagger sees a cover now and passes none: the picture count stays.
      await safe.write(song, const TagChanges(discNumber: 2), backup: false);
      final twice = await reader.read(song);
      expect(twice.coverBytes!.length, once.coverBytes!.length);
      expect(Directory(p.join(root.path, 'bk')).existsSync(), isFalse);
    });
  }
}
