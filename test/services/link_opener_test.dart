import 'package:codecore/services/issue/link_opener.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('on Android openUrl and deviceInfo go through codecore/link', () async {
    const ch = MethodChannel('codecore/link');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (c) async {
          calls.add(c);
          return c.method == 'openUrl'
              ? true
              : {'model': 'M', 'os': '14', 'build': '1'};
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ch, null),
    );
    final o = LinkOpener(channel: ch, android: true);
    expect(await o.open('https://github.com/x'), isTrue);
    expect(calls.single.method, 'openUrl');
    expect(calls.single.arguments, {'url': 'https://github.com/x'});
    expect((await o.deviceInfo())['model'], 'M');
  });

  test('a failing channel answers false / empty instead of throwing', () async {
    const ch = MethodChannel('codecore/link');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          ch,
          (c) async => throw PlatformException(code: 'x'),
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ch, null),
    );
    final o = LinkOpener(channel: ch, android: true);
    expect(await o.open('https://github.com/x'), isFalse);
    expect(await o.deviceInfo(), isEmpty);
  });

  test('off Android there is no device info from the channel', () async {
    expect(await LinkOpener(android: false).deviceInfo(), isEmpty);
  });
}
