import 'dart:convert';

import '../../../core/app_log.dart';

/// One MQTT broker the remote Jam can use (R-122).
class BrokerEntry {
  const BrokerEntry({required this.host, required this.port, this.tls = true});

  final String host;
  final int port;
  final bool tls;

  /// Host not empty and without spaces, port 1..65535.
  bool get isValid =>
      host.isNotEmpty && !host.contains(RegExp(r'\s')) && port >= 1 && port <= 65535;

  Map<String, Object> toJson() => {'host': host, 'port': port, 'tls': tls};

  @override
  bool operator ==(Object other) =>
      other is BrokerEntry && other.host == host && other.port == port && other.tls == tls;

  @override
  int get hashCode => Object.hash(host, port, tls);

  @override
  String toString() => '$host:$port';
}

/// Append only: the BLE announcement carries an index into this list.
const kDefaultJamBrokers = [
  BrokerEntry(host: 'broker.emqx.io', port: 8883),
  BrokerEntry(host: 'test.mosquitto.org', port: 8886),
];

String encodeBrokers(List<BrokerEntry> l) => jsonEncode([for (final b in l) b.toJson()]);

/// Reads `[{host, port, tls}]`; null or broken text gives the defaults, invalid entries are dropped.
List<BrokerEntry> decodeBrokers(String? raw) {
  if (raw == null) return kDefaultJamBrokers;
  try {
    final out = <BrokerEntry>[
      for (final e in jsonDecode(raw) as List)
        BrokerEntry(
          host: ((e as Map)['host'] as String).trim(),
          port: e['port'] as int,
          tls: e['tls'] as bool? ?? true,
        ),
    ].where((b) => b.isValid).toList();
    return out;
  } on Object catch (e, st) {
    AppLog.w('jamBrokers unreadable, using the defaults', e, st);
    return kDefaultJamBrokers;
  }
}
