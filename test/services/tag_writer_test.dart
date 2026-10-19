import 'dart:io';

import 'package:codecore/services/tags/safe_tag_writer.dart';
import 'package:codecore/services/tags/tag_backups.dart';
import 'package:codecore/services/tags/tag_reader.dart';
import 'package:codecore/services/tags/tag_writer.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Fake "audio files": line 1 is the audio, the rest is `key=value` tags.
String _file(String audio, Map<String, String> tags) =>
    '$audio\n${tags.entries.map((e) => '${e.key}=${e.value}').join('\n')}';

Map<String, String> _tagsOf(String path) => {
  for (final l in File(path).readAsLinesSync().skip(1))
    if (l.contains('='))
      l.substring(0, l.indexOf('=')): l.substring(l.indexOf('=') + 1),
};

class _Reader implements TagReader {
  @override
  Future<TagInfo> read(String path, {bool withCover = true}) async {
    final t = _tagsOf(path);
    return TagInfo(
      title: t['title'],
      artist: t['artist'],
      album: t['album'],
      year: int.tryParse(t['year'] ?? ''),
      durationMs: 1000,
    );
  }
}

enum _Mode { ok, failsAfterWrite, wrongTags }

class _Writer implements TagWriter {
  _Writer([this.mode = _Mode.ok]);

  final _Mode mode;
  int calls = 0;

  @override
  bool supports(String format) => format == 'mp3';

  @override
  Future<void> write(String path, TagChanges c) async {
    calls++;
    final tags = _tagsOf(path);
    if (c.title != null) tags['title'] = c.title!;
    if (c.artist != null) tags['artist'] = c.artist!;
    if (c.year != null) tags['year'] = '${c.year}';
    if (mode == _Mode.wrongTags) tags.remove('title');
    final audio = File(path).readAsLinesSync().first;
    File(path).writeAsStringSync(_file(audio, tags));
    if (mode == _Mode.failsAfterWrite) {
      throw const TagWriteException(TagWriteReason.writeFailed, 'boom');
    }
  }
}

String _hash(String path) => sha256.convert(File(path).readAsBytesSync()).toString();

void main() {
  group('tagMismatch tolerates only the reader quirks', () {
    const before = TagInfo(title: 'Old', artist: 'Me', album: 'Alb');

    test('mp3: the album artist comes back as the artist', () {
      const after = TagInfo(title: 'Old', artist: 'Fab', album: 'Alb');
      expect(
        tagMismatch(before, after, const TagChanges(albumArtist: 'Fab'), format: 'mp3'),
        isNull,
      );
    });

    test('flac: an unreadable year is accepted, a wrong title is not', () {
      const after = TagInfo(title: 'Old', artist: 'Me', album: 'Alb');
      expect(tagMismatch(before, after, const TagChanges(year: 1999), format: 'flac'), isNull);
      expect(tagMismatch(before, after, const TagChanges(year: 1999), format: 'mp3'), contains('year'));
      expect(tagMismatch(before, after, const TagChanges(title: 'New'), format: 'flac'), contains('title'));
    });

    test('an untouched artist that changed is caught; a lost cover too', () {
      const moved = TagInfo(title: 'Old', artist: 'Other', album: 'Alb');
      expect(tagMismatch(before, moved, const TagChanges(title: 'Old')), contains('artist'));
      const withCover = TagInfo(title: 'Old', artist: 'Me', album: 'Alb', coverBytes: [1, 2]);
      expect(tagMismatch(withCover, before, const TagChanges(title: 'Old')), contains('cover'));
    });
  });

  late Directory root;
  late String song;
  late Directory work, backupDir;

  SafeTagWriter make(
    TagWriter w, {
    int maxCount = 200,
    Future<void> Function(String, String)? rename,
  }) => SafeTagWriter(
    writer: w,
    reader: _Reader(),
    workDir: work,
    backups: TagBackupStore(backupDir, maxCount: maxCount),
    rename: rename,
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('tagw');
    work = Directory(p.join(root.path, 'tagwork'));
    backupDir = Directory(p.join(root.path, 'tag_backups'));
    song = p.join(root.path, 'a.mp3');
    File(song).writeAsStringSync(
      _file('AUDIO-BYTES', {'title': 'Old', 'artist': 'Me', 'album': 'Alb'}),
    );
  });
  tearDown(() => root.deleteSync(recursive: true));

  List<FileSystemEntity> leftovers() =>
      work.existsSync() ? work.listSync() : const [];

  test('success: new tags, audio line intact, backup of the original, no leftovers', () async {
    final before = _hash(song);
    final w = make(_Writer());
    final stamp = await w.write(
      song,
      const TagChanges(title: 'New', artist: 'You', year: 1999),
    );

    final tags = _tagsOf(song);
    expect(tags['title'], 'New');
    expect(tags['artist'], 'You');
    expect(tags['year'], '1999');
    expect(tags['album'], 'Alb', reason: 'untouched field kept');
    expect(File(song).readAsLinesSync().first, 'AUDIO-BYTES');
    expect(stamp.sizeBytes, File(song).lengthSync());
    expect(stamp.mtimeMs, File(song).statSync().modified.millisecondsSinceEpoch);

    final backups = await TagBackupStore(backupDir).list();
    expect(backups, hasLength(1));
    expect(backups.single.path, song);
    expect(_hash(p.join(backupDir.path, '${backups.single.id}.bak')), before);
    expect(leftovers(), isEmpty);
  });

  test('the writer fails after writing the copy: original identical, no backup', () async {
    final before = _hash(song);
    final w = make(_Writer(_Mode.failsAfterWrite));
    await expectLater(
      w.write(song, const TagChanges(title: 'New')),
      throwsA(isA<TagWriteException>()),
    );
    expect(_hash(song), before);
    expect(await TagBackupStore(backupDir).list(), isEmpty);
    expect(leftovers(), isEmpty);
  });

  test('tags read back differ from what was written: refused, original identical', () async {
    final before = _hash(song);
    await expectLater(
      make(_Writer(_Mode.wrongTags)).write(song, const TagChanges(title: 'New')),
      throwsA(
        isA<TagWriteException>().having((e) => e.reason, 'reason', TagWriteReason.verifyFailed),
      ),
    );
    expect(_hash(song), before);
    expect(await TagBackupStore(backupDir).list(), isEmpty);
    expect(leftovers(), isEmpty);
  });

  test('unsupported format and missing file never reach the writer', () async {
    final flac = p.join(root.path, 'b.flac');
    File(flac).writeAsStringSync('x');
    final fake = _Writer();
    final w = make(fake);
    await expectLater(
      w.write(flac, const TagChanges(title: 'T')),
      throwsA(isA<TagWriteException>().having((e) => e.reason, 'r', TagWriteReason.unsupported)),
    );
    await expectLater(
      w.write(p.join(root.path, 'none.mp3'), const TagChanges(title: 'T')),
      throwsA(isA<TagWriteException>().having((e) => e.reason, 'r', TagWriteReason.notFound)),
    );
    expect(fake.calls, 0);
  });

  test('a read-only file is refused with its own reason', () async {
    if (Platform.isWindows) return;
    Process.runSync('chmod', ['444', song]);
    if (Process.runSync('id', ['-u']).stdout.toString().trim() == '0') return;
    final before = _hash(song);
    final w = make(_Writer());
    expect(await w.check(song), TagWriteReason.readOnly);
    await expectLater(
      w.write(song, const TagChanges(title: 'T')),
      throwsA(isA<TagWriteException>().having((e) => e.reason, 'r', TagWriteReason.readOnly)),
    );
    expect(_hash(song), before);
  });

  test('rename across partitions falls back to copy + rename next to the file', () async {
    var first = true;
    final w = make(
      _Writer(),
      rename: (a, b) async {
        if (first) {
          first = false;
          throw const FileSystemException('Invalid cross-device link');
        }
        await File(a).rename(b);
      },
    );
    await w.write(song, const TagChanges(title: 'Moved'));
    expect(_tagsOf(song)['title'], 'Moved');
    expect(
      root.listSync().map((e) => p.basename(e.path)).toSet(),
      {'a.mp3', 'tagwork', 'tag_backups'},
      reason: 'no .codecore-new left beside the song',
    );
    expect(leftovers(), isEmpty);
  });

  test('backups are pruned to the last N and a restore puts the original back', () async {
    final w = make(_Writer(), maxCount: 2);
    final original = _hash(song);
    for (final t in ['One', 'Two', 'Three']) {
      await w.write(song, TagChanges(title: t));
      await Future<void>.delayed(const Duration(milliseconds: 3));
    }
    final store = TagBackupStore(backupDir, maxCount: 2);
    final list = await store.list();
    expect(list, hasLength(2));

    // The oldest one left is the file as it was before "Two".
    final stamp = await store.restore(list.last);
    expect(_tagsOf(song)['title'], 'One');
    expect(stamp.sizeBytes, File(song).lengthSync());
    expect(_hash(song), isNot(original), reason: 'the very first original was pruned');

    await store.delete(list.first);
    expect(await store.list(), hasLength(1));
  });
}
