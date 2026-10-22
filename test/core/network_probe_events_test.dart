import 'package:codecore/core/network_kind.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('repeated identical «changed» events are tolerated', () async {
    const channel = MethodChannel('codecore/net');
    final probe = NetworkProbe(channel: channel, android: true)..listen();
    var n = 0;
    final sub = probe.changes.listen((_) => n++);
    for (var i = 0; i < 5; i++) {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('codecore/net',
              const StandardMethodCodec().encodeMethodCall(const MethodCall('changed')), (_) {});
    }
    await Future<void>.delayed(Duration.zero);
    expect(n, 5);
    await sub.cancel();
    probe.dispose();
  });
}
