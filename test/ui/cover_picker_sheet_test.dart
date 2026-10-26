import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:codecore/providers/online_providers.dart';
import 'package:codecore/services/online/http_client.dart';
import 'package:codecore/ui/widgets/cover_picker_sheet.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

/// A 1x1 PNG.
final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC');

class _Web implements WebClient {
  _Web({this.deezerDown = false});

  final bool deezerDown;
  final calls = <String>[];

  @override
  Future<Object?> getJson(String url, {Map<String, String>? query, CancelToken? cancel, bool strict = false}) async {
    calls.add(url);
    if (url.contains('deezer')) {
      return deezerDown
          ? null
          : {'data': [{'title': 'Alb', 'cover_xl': 'https://d/1.jpg'}]};
    }
    return {'results': [{'collectionName': 'Alb', 'artworkUrl100': 'https://i/100x100bb.jpg'}]};
  }

  @override
  Future<List<int>?> getBytes(String url, {int maxBytes = 0, CancelToken? cancel}) async => _png;
}

base class _Picked extends PlatformFile {
  _Picked(this._path);

  final String _path;

  @override
  String get name => 'big.jpg';
  @override
  Uri get uri => Uri.file(_path);
  @override
  get xFile => throw UnimplementedError();
  @override
  int? lengthSync() => null;
  @override
  Future<int?> length() async => null;
  @override
  Future<Uint8List> readAsBytes() => File(_path).readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() => throw UnimplementedError();
}

class _Picker extends FilePickerPlatform {
  _Picker(this.path);

  final String path;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool? withData,
    bool? withReadStream,
    bool lockParentWindow = false,
    bool readSequential = false,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => [_Picked(path)];
}

Future<void> _settle(WidgetTester tester) async {
  // The image codec answers on the real event loop, between pumps.
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<Harness> _open(
  WidgetTester tester,
  _Web web, {
  bool withOnline = true,
  List<String>? libraryKeys,
  CoverSave? save,
  Harness? harness,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final h = harness ?? await Harness.create(tester, tracks: 1);
  await h.pump(
    tester,
    extraOverrides: [webClientProvider.overrideWithValue(web)],
    Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showCoverPicker(
            context,
            save: save ?? (ops, bytes, mime) async => true,
            online: withOnline ? (album: 'Alb', artist: 'Art') : null,
            libraryKeys: libraryKeys,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  return h;
}

void main() {
  testWidgets('online proposals are searched only on opening, once per source, with «L × A» each', (tester) async {
    final web = _Web();
    final h = await _open(tester, web);
    expect(web.calls, isEmpty);
    await tester.tap(find.text('open'));
    await _settle(tester);
    expect(web.calls, hasLength(2), reason: 'Deezer and iTunes, with «Metadati da Deezer» off');
    expect(find.text('Dal dispositivo'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('1 × 1'), findsNWidgets(2));
    await h.dispose(tester);
  });

  testWidgets('tapping an online proposal saves its bytes with their mime and closes the sheet', (tester) async {
    List<int>? saved;
    String? mime;
    final h = await _open(tester, _Web(), save: (ops, b, m) async {
      saved = b;
      mime = m;
      return true;
    });
    await tester.tap(find.text('open'));
    await _settle(tester);
    await tester.tap(find.text('1 × 1').first);
    await _settle(tester);
    expect(saved, _png);
    expect(mime, 'image/png');
    expect(find.text('Online'), findsNothing, reason: 'the sheet is closed');
    await h.dispose(tester);
  });

  testWidgets('a source in error leaves the other one\'s proposals', (tester) async {
    final h = await _open(tester, _Web(deezerDown: true));
    await tester.tap(find.text('open'));
    await _settle(tester);
    expect(find.text('1 × 1'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('a playlist (no online) offers the covers it was given; no «Online» section', (tester) async {
    final web = _Web();
    final h = await _open(tester, web, withOnline: false, libraryKeys: ['k1', 'k2']);
    await tester.tap(find.text('open'));
    await _settle(tester);
    expect(find.byKey(const ValueKey('library-cover-k1')), findsOneWidget);
    expect(find.byKey(const ValueKey('library-cover-k2')), findsOneWidget);
    expect(find.text('Online'), findsNothing);
    expect(web.calls, isEmpty);
    await h.dispose(tester);
  });

  testWidgets('a file over the limit says so and saves nothing', (tester) async {
    final dir = (await tester.runAsync(Directory.systemTemp.createTemp))!;
    addTearDown(() => dir.deleteSync(recursive: true));
    final big = File('${dir.path}/big.jpg');
    await tester.runAsync(() => big.writeAsBytes(List.filled(4 * 1024 * 1024 + 1, 1)));
    FilePickerPlatform.instance = _Picker(big.path);
    final h = await Harness.create(tester, tracks: 1);
    h.coversDir = Directory('${dir.path}/covers');
    final id = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!.first.id;
    await _open(tester, _Web(), harness: h, save: (ops, b, m) => ops.setTrackCover(id, b, m));
    await tester.tap(find.text('open'));
    await _settle(tester);
    await tester.tap(find.text('Dal dispositivo'));
    await _settle(tester);
    expect(find.text('Immagine troppo grande (max 4 MB)'), findsOneWidget);
    final t = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!.first;
    expect(t.coverSource, 0);
    await h.dispose(tester);
  });
}
