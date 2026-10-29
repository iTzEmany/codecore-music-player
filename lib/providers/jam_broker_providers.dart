import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../services/jam/remote/broker_entry.dart';
import '../services/jam/remote/mqtt_link.dart';
import 'settings_providers.dart';

/// The brokers of the remote Jam, saved on every change (R-122).
class JamBrokersNotifier extends Notifier<List<BrokerEntry>> {
  @override
  List<BrokerEntry> build() => decodeBrokers(ref.read(settingsStoreProvider).readJamBrokersRaw());

  void _set(List<BrokerEntry> next, {bool reset = false}) {
    state = next;
    ref
        .read(settingsStoreProvider)
        .writeJamBrokersRaw(reset ? null : encodeBrokers(next))
        .catchError((Object e, StackTrace st) {
      AppLog.w('could not save the brokers', e, st);
    });
  }

  /// False when [b] is invalid or already there.
  bool add(BrokerEntry b) {
    if (!b.isValid || state.contains(b)) return false;
    _set([...state, b]);
    return true;
  }

  /// The last broker stays (D-270).
  void remove(BrokerEntry b) {
    if (state.length > 1) _set([...state]..remove(b));
  }

  void move(int from, int to) {
    final l = [...state];
    l.insert(to > from ? to - 1 : to, l.removeAt(from));
    _set(l);
  }

  void restore() => _set(kDefaultJamBrokers, reset: true);
}

final jamBrokersProvider =
    NotifierProvider<JamBrokersNotifier, List<BrokerEntry>>(JamBrokersNotifier.new);

/// Makes the MQTT link; tests override it with a fake.
final mqttLinkFactoryProvider = Provider<MqttLink Function()>((_) => MqttClientLink.new);

/// Connects, subscribes and publishes on a random channel, waits for the message
/// to come back (5 s), disconnects. True = ok (the reason goes to the log).
Future<bool> testBroker(MqttLink link, BrokerEntry b,
    {Duration timeout = const Duration(seconds: 5)}) async {
  final r = Random.secure();
  final topic = 'ccj1/t/${randomClientId(r)}';
  final payload = Uint8List.fromList([for (var i = 0; i < 8; i++) r.nextInt(256)]);
  try {
    await link.connect(b);
    final back = link.messages
        .firstWhere((m) => m.topic == topic && listEquals(m.payload, payload))
        .timeout(timeout);
    back.ignore();
    link.subscribe(topic);
    link.publish(topic, payload);
    await back;
    return true;
  } on Object catch (e, st) {
    AppLog.w('broker test failed: $b', e, st);
    return false;
  } finally {
    // Not inside the stream callback that woke us: the client cannot close its subscriptions there.
    await Future<void>.delayed(Duration.zero);
    link.disconnect();
  }
}
