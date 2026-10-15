import 'package:codecore/services/share/share_notifier.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('codecore/share');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  test('service and offer notifications go to the platform', () async {
    final n = AndroidShareNotifier();
    await n.startService(title: 'T', text: 'X', disable: 'Off');
    await n.showOffer(
        offerId: 'o1', title: 'A', body: 'B', accept: 'Yes', decline: 'No');
    await n.clearOffer('o1');
    await n.stopService();
    expect(calls.map((c) => c.method),
        ['startService', 'showOffer', 'clearOffer', 'stopService']);
    expect((calls[1].arguments as Map)['offerId'], 'o1');
  });

  test('notification buttons call back into Dart', () async {
    final n = AndroidShareNotifier();
    String? id;
    bool? accepted;
    var disabled = false;
    n.onOfferAction = (o, a) {
      id = o;
      accepted = a;
    };
    n.onDisableReceive = () => disabled = true;

    Future<void> fromNative(String method, Object? args) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(MethodCall(method, args)),
        (_) {},
      );
    }

    await fromNative('offerAction', {'offerId': 'o9', 'action': 'accept'});
    expect(id, 'o9');
    expect(accepted, true);
    await fromNative('offerAction', {'offerId': 'o9', 'action': 'decline'});
    expect(accepted, false);
    await fromNative('disableReceive', null);
    expect(disabled, true);
  });
}
