import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'broker_entry.dart';

/// A message that came back from the broker.
typedef MqttIncoming = ({String topic, Uint8List payload});

/// The small slice of MQTT the remote Jam needs. Faked in tests.
abstract class MqttLink {
  /// Throws when the broker cannot be reached or refuses (bad certificate included).
  Future<void> connect(BrokerEntry broker);
  void subscribe(String topic);
  void unsubscribe(String topic);
  void publish(String topic, Uint8List bytes, {bool retain = false});
  Stream<MqttIncoming> get messages;
  bool get connected;
  void disconnect();
}

/// Random 20-character client id, new at every connection (R-133).
String randomClientId([Random? rng]) {
  final r = rng ?? Random.secure();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return String.fromCharCodes([for (var i = 0; i < 20; i++) chars.codeUnitAt(r.nextInt(chars.length))]);
}

class MqttClientLink implements MqttLink {
  MqttClientLink({this.timeout = const Duration(seconds: 8)});

  final Duration timeout;
  MqttServerClient? _c;

  @override
  Future<void> connect(BrokerEntry b) async {
    final id = randomClientId();
    final c = MqttServerClient.withPort(b.host, id, b.port)
      ..secure = b.tls
      ..securityContext = SecurityContext.defaultContext // R-129: onBadCertificate stays null
      ..keepAlivePeriod = 30
      ..autoReconnect = false
      ..logging(on: false)
      ..setProtocolV311()
      ..connectTimeoutPeriod = timeout.inMilliseconds
      ..connectionMessage = MqttConnectMessage().withClientIdentifier(id).startClean();
    _c = c;
    try {
      final st = await c.connect().timeout(timeout);
      if (st?.state != MqttConnectionState.connected) {
        throw StateError('MQTT refused: ${st?.returnCode}');
      }
    } on Object {
      c.disconnect();
      rethrow;
    }
  }

  @override
  void subscribe(String topic) {
    assert(!topic.contains('#') && !topic.contains('+'));
    _c!.subscribe(topic, MqttQos.atLeastOnce);
  }

  @override
  void unsubscribe(String topic) => _c?.unsubscribe(topic);

  @override
  void publish(String topic, Uint8List bytes, {bool retain = false}) {
    final b = MqttClientPayloadBuilder();
    b.payload!.addAll(bytes);
    _c!.publishMessage(topic, MqttQos.atLeastOnce, b.payload!, retain: retain);
  }

  @override
  Stream<MqttIncoming> get messages => _c!.updates!.expand((l) => l).map((m) {
        final p = (m.payload as MqttPublishMessage).payload.message;
        return (topic: m.topic, payload: Uint8List.fromList(p));
      });

  @override
  bool get connected => _c?.connectionStatus?.state == MqttConnectionState.connected;

  @override
  void disconnect() => _c?.disconnect();
}
