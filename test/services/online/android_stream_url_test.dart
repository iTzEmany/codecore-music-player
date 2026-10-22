import 'package:codecore/services/online/android_yt_dlp_service.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('codecore/ytdlp');
  const video = YtResult(id: 'v', title: 'T', channel: 'C', duration: Duration(minutes: 3));
  final calls = <Map>[];

  void answer(Future<Object?> Function(Map args) f) {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) {
      final args = Map<String, Object?>.from(c.arguments as Map);
      calls.add(args);
      return f(args);
    });
  }

  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  test('the fast android_vr client answers: one call, no default clients', () async {
    answer((a) async =>
        '{"url":"https://media.example/fast","http_headers":{"User-Agent":"vr"}}\n');
    final a = await AndroidYtDlpService().streamUrl(video);
    expect(a.uri.toString(), 'https://media.example/fast');
    expect(a.headers, {'User-Agent': 'vr'});
    expect(a.fast, isTrue);
    expect(calls.single['fast'], true);
  });

  test('when the fast client fails, the default clients are tried', () async {
    answer((a) async {
      if (a['fast'] == true) throw PlatformException(code: 'YTDLP', message: 'ERROR: Sign in to confirm your age');
      return 'https://media.example/default';
    });
    final a = await AndroidYtDlpService().streamUrl(video);
    expect(a.uri.toString(), 'https://media.example/default');
    expect(a.fast, isFalse);
    expect(calls.map((c) => c['fast']), [true, null]);
  });

  test('fast: false goes straight to the default clients', () async {
    answer((a) async => 'https://media.example/default\n');
    final a = await AndroidYtDlpService().streamUrl(video, fast: false);
    expect(a.fast, isFalse);
    expect(calls.map((c) => c['fast']), [null]);
  });
}
