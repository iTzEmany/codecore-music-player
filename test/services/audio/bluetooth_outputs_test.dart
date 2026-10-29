import 'package:codecore/services/audio/bluetooth_outputs.dart';
import 'package:codecore/services/audio/output_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('codecore/audio');

  void mock(Future<Object?> Function(MethodCall) h) =>
      messenger.setMockMethodCallHandler(channel, h);

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('parses outputs and tolerates bad entries', () async {
    mock((_) async => {
          'permission': true,
          'outputs': [
            {'name': 'Cassa', 'address': 'AA', 'deviceClass': 1048},
            {'address': 'BB'},
            {'name': 'x'},
            'junk',
          ],
        });
    final s = await fetchBluetoothOutputs();
    expect(s.permission, isTrue);
    expect(s.outputs.map((o) => o.address), ['AA', 'BB']);
    expect(s.outputs[0].deviceClass, 1048);
    expect(s.outputs[1].name, 'BB');
    expect(s.outputs[1].deviceClass, isNull);
  });

  test('permission false and channel error give the empty snapshot', () async {
    mock((_) async => {'permission': false, 'outputs': []});
    expect((await fetchBluetoothOutputs()).permission, isFalse);
    mock((_) async => throw PlatformException(code: 'x'));
    final s = await fetchBluetoothOutputs();
    expect(s.permission, isFalse);
    expect(s.outputs, isEmpty);
    expect(await bluetoothPermission(), isFalse);
  });

  test('bluetoothOutputActive asks the exact method; error gives false', () async {
    String? method;
    mock((c) async {
      method = c.method;
      return true;
    });
    expect(await bluetoothOutputActive(), isTrue);
    expect(method, 'bluetoothOutputActive');
    mock((_) async => throw PlatformException(code: 'x'));
    expect(await bluetoothOutputActive(), isFalse);
  });

  test('non-Android never calls the channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    var called = false;
    mock((_) async {
      called = true;
      return null;
    });
    expect((await fetchBluetoothOutputs()).outputs, isEmpty);
    expect(await requestBluetoothPermission(), isFalse);
    expect(called, isFalse);
  });

  test('events reach the streams and outputRoute still works', () async {
    mock((c) async => c.method == 'outputRoute' ? 'speaker' : null);
    final routes = <bool>[];
    watchOutputRoute(routes.add);
    var changed = 0, seen = 0;
    final a = bluetoothChanged.listen((_) => changed++);
    final b = bluetoothOutputSeen.listen((_) => seen++);
    Future<void> push(String m, Object? args) => messenger.handlePlatformMessage(
        'codecore/audio', channel.codec.encodeMethodCall(MethodCall(m, args)), (_) {});
    await push('bluetoothChanged', null);
    await push('bluetoothOutputSeen', null);
    await push('outputRoute', 'headphones');
    await Future<void>.delayed(Duration.zero);
    expect([changed, seen], [1, 1]);
    expect(routes.last, isTrue);
    await a.cancel();
    await b.cancel();
  });
}
