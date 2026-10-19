import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:codecore/services/theme/background_image.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _png(int w, int h) async {
  final rec = ui.PictureRecorder();
  ui.Canvas(rec).drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = const ui.Color(0xFF3366CC));
  final img = await rec.endRecording().toImage(w, h);
  return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

Future<ui.Image> _decode(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

void main() {
  late Directory tmp, out;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('bgimg');
    out = Directory('${tmp.path}/theme');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('a big picture is scaled so its longer side is 1600 and kept as a PNG', () async {
    final src = File('${tmp.path}/a.png')..writeAsBytesSync(await _png(4000, 2000));
    final path = (await importBackgroundImage(src, out, 'sea'))!;
    expect(path, startsWith('${out.path}/bg-sea-'));
    expect(path, endsWith('.png'));
    final img = await _decode(path);
    expect(img.width, 1600);
    expect(img.height, 800);
  });

  test('a small picture keeps its size; a portrait one is limited on its height', () async {
    final small = File('${tmp.path}/s.png')..writeAsBytesSync(await _png(300, 200));
    final img = await _decode((await importBackgroundImage(small, out, 'sea'))!);
    expect([img.width, img.height], [300, 200]);

    final tall = File('${tmp.path}/t.png')..writeAsBytesSync(await _png(1000, 3000));
    final t = await _decode((await importBackgroundImage(tall, out, 't'))!);
    expect([t.width, t.height], [533, 1600]);
  });

  test('a new picture replaces the older ones of the same theme only', () async {
    final src = File('${tmp.path}/a.png')..writeAsBytesSync(await _png(50, 50));
    final first = (await importBackgroundImage(src, out, 'sea'))!;
    final other = (await importBackgroundImage(src, out, 'other'))!;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = (await importBackgroundImage(src, out, 'sea'))!;
    expect(File(first).existsSync(), isFalse);
    expect(File(second).existsSync(), isTrue);
    expect(File(other).existsSync(), isTrue, reason: 'another theme\'s picture is not touched');
  });

  test('something that is not a picture, or a missing file, gives null and writes nothing', () async {
    final txt = File('${tmp.path}/x.png')..writeAsStringSync('hello');
    expect(await importBackgroundImage(txt, out, 'sea'), isNull);
    expect(await importBackgroundImage(File('${tmp.path}/none.png'), out, 'sea'), isNull);
    expect(out.existsSync() ? out.listSync() : <FileSystemEntity>[], isEmpty);
  });

  test('prune keeps what is listed and never touches other files', () async {
    out.createSync(recursive: true);
    final keep = File('${out.path}/bg-a-1.png')..writeAsBytesSync([1]);
    final drop = File('${out.path}/bg-b-2.png')..writeAsBytesSync([1]);
    final other = File('${out.path}/notes.txt')..writeAsStringSync('mine');
    final odd = File('${out.path}/bg-c-3.jpg')..writeAsBytesSync([1]);
    await pruneBackgroundImages(out, {keep.path});
    expect(keep.existsSync(), isTrue);
    expect(drop.existsSync(), isFalse);
    expect(other.existsSync(), isTrue);
    expect(odd.existsSync(), isTrue);
    await pruneBackgroundImages(Directory('${tmp.path}/missing'), {});
  });

  test('deleteBackgroundImages removes one theme\'s pictures, optionally all but one', () async {
    out.createSync(recursive: true);
    final a1 = File('${out.path}/bg-a-1.png')..writeAsBytesSync([1]);
    final a2 = File('${out.path}/bg-a-2.png')..writeAsBytesSync([1]);
    final b1 = File('${out.path}/bg-b-1.png')..writeAsBytesSync([1]);
    await deleteBackgroundImages(out, 'a', except: a2.path);
    expect([a1.existsSync(), a2.existsSync(), b1.existsSync()], [false, true, true]);
    await deleteBackgroundImages(out, 'a');
    expect(a2.existsSync(), isFalse);
    expect(b1.existsSync(), isTrue);
  });
}
