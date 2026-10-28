import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/android_yt_dlp_service.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _ch = MethodChannel('codecore/ytdlp');
final _ytdlpUrl = Uri.parse('https://ytdlp.example/a');
final _pipeUrl = Uri.parse('https://newpipe.example/a');

/// Sends the two marked lines yt-dlp prints before the download.
Future<void> _ytdlpLines() async {
  for (final line in [
    'CODECORE_URL $_ytdlpUrl',
    'CODECORE_HDR ${jsonEncode({'User-Agent': 'x'})}',
  ]) {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          _ch.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('progress', {'processId': 'dl-0', 'line': line}),
          ),
          (_) {},
        );
  }
}

/// Runs one download with the given fake `streamUrl` and `download` and
/// returns the stream URLs that came out.
Future<List<Uri>> _run(
  Future<Object?> Function() streamUrl,
  Future<void> Function() download,
) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_ch, (call) async {
        if (call.method == 'streamUrl') return streamUrl();
        if (call.method == 'download') {
          await download();
          return '/tmp/x.m4a';
        }
        return null;
      });
  final dir = Directory.systemTemp.createTempSync('ytdl');
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_ch, null);
    dir.deleteSync(recursive: true);
  });
  final events = AndroidYtDlpService().download(
    const YtResult(
      id: 'abc',
      title: 't',
      channel: 'c',
      duration: Duration(seconds: 1),
    ),
    dir,
    options: const DownloadOptions(emitStreamUrl: true),
  );
  return [
    await for (final e in events)
      if (e.streamUrl != null) e.streamUrl!,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, Object?> pipe() => {
    'url': '$_pipeUrl',
    'headers': {'User-Agent': 'x'},
  };

  test('NewPipe first: one stream url event, the NewPipe one', () async {
    final urls = await _run(
      () async => pipe(),
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await _ytdlpLines();
      },
    );
    expect(urls, [_pipeUrl]);
  });

  test('NewPipe fails: the yt-dlp url is used', () async {
    final urls = await _run(
      () async => throw PlatformException(code: 'YTDLP'),
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await _ytdlpLines();
      },
    );
    expect(urls, [_ytdlpUrl]);
  });

  test('NewPipe answers without a url: the yt-dlp url is used', () async {
    final urls = await _run(
      () async => {'headers': {'User-Agent': 'x'}},
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await _ytdlpLines();
      },
    );
    expect(urls, [_ytdlpUrl]);
  });

  test('NewPipe after yt-dlp: ignored', () async {
    final urls = await _run(
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return pipe();
      },
      () async {
        await _ytdlpLines();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
    );
    expect(urls, [_ytdlpUrl]);
  });
}
