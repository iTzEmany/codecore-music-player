import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/app_log.dart';
import 'offers.dart';

/// Magic string carried by every beacon; anything else is ignored.
const discoveryMagic = 'CODECORE/1';
const discoveryPort = 45671;

class Peer {
  const Peer({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.platform,
    this.tlsPort,
  });

  final String id, name, host, platform;

  /// HTTP port of the peer's offer endpoint (also what a v2 device speaks).
  final int port;

  /// HTTPS port of the same endpoint; null for a device without identity (v2).
  final int? tlsPort;
}

/// Announces this device and lists the Codecore devices on the same network
/// using small UDP broadcast beacons. Only datagrams from local-network
/// addresses are considered, and beacons carry no secrets.
class LanDiscovery {
  LanDiscovery({
    required this.deviceId,
    required this.deviceName,
    this.port = discoveryPort,
    this.interval = const Duration(seconds: 2),
    this.peerTtl = const Duration(seconds: 7),
    this.allowLoopback = false,
    List<({InternetAddress address, int port})>? targets,
  }) : _fixedTargets = targets;

  final String deviceId, deviceName;
  final int port;
  final Duration interval, peerTtl;
  final bool allowLoopback;
  final List<({InternetAddress address, int port})>? _fixedTargets;

  RawDatagramSocket? _socket;
  Timer? _beat;
  int _httpPort = 0;
  int? _tlsPort;
  final _peers = <String, ({Peer peer, DateTime seen})>{};
  final _controller = StreamController<List<Peer>>.broadcast();

  Stream<List<Peer>> get peers => _controller.stream;
  List<Peer> get current =>
      [for (final e in _peers.values) e.peer]..sort((a, b) => a.name.compareTo(b.name));

  static String get platformName => Platform.isAndroid
      ? 'android'
      : Platform.isWindows
          ? 'windows'
          : Platform.isLinux
              ? 'linux'
              : 'other';

  Future<void> start(int httpPort, {int? tlsPort}) async {
    await stop();
    _tlsPort = tlsPort;
    _httpPort = httpPort;
    // SO_REUSEPORT is unsupported by Dart on Android and Windows.
    final reusePort = Platform.isLinux || Platform.isMacOS;
    final s = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
      reusePort: reusePort,
    );
    s.broadcastEnabled = true;
    s.listen(_onEvent(s));
    _socket = s;
    _send();
    _beat = Timer.periodic(interval, (_) {
      _send();
      _prune();
    });
    AppLog.i('discovery: started on $port');
  }

  Future<void> stop() async {
    _beat?.cancel();
    _beat = null;
    _socket?.close();
    _socket = null;
    if (_peers.isNotEmpty) {
      _peers.clear();
      if (!_controller.isClosed) _controller.add(const []);
    }
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  void Function(RawSocketEvent) _onEvent(RawDatagramSocket s) => (event) {
        if (event != RawSocketEvent.read) return;
        Datagram? d;
        while ((d = s.receive()) != null) {
          _handle(d!);
        }
      };

  void _handle(Datagram d) {
    if (d.data.length > 512) return;
    final src = d.address.address;
    if (!isLocalNetworkAddress(src, allowLoopback: allowLoopback)) return;
    try {
      final j = jsonDecode(utf8.decode(d.data));
      if (j is! Map || j['m'] != discoveryMagic) return;
      final id = j['id'], name = j['name'], port = j['port'];
      if (id is! String || name is! String || port is! int) return;
      if (id == deviceId || id.isEmpty || id.length > 64) return;
      if (port < 1 || port > 65535) return;
      final isNew = !_peers.containsKey(id);
      _peers[id] = (
        peer: Peer(
          id: id,
          name: name.length > 60 ? name.substring(0, 60) : name,
          host: src,
          port: port,
          tlsPort: j['tlsPort'] is int && (j['tlsPort'] as int) > 0 && (j['tlsPort'] as int) < 65536
              ? j['tlsPort'] as int
              : null,
          platform: j['p'] is String ? j['p'] as String : 'other',
        ),
        seen: DateTime.now(),
      );
      if (isNew && !_controller.isClosed) _controller.add(current);
    } on FormatException {
      // Not one of ours.
    }
  }

  void _prune() {
    final cutoff = DateTime.now().subtract(peerTtl);
    final before = _peers.length;
    _peers.removeWhere((_, v) => v.seen.isBefore(cutoff));
    if (_peers.length != before && !_controller.isClosed) {
      _controller.add(current);
    }
  }

  Future<List<({InternetAddress address, int port})>> _targets() async {
    final fixed = _fixedTargets;
    if (fixed != null) return fixed;
    final out = <({InternetAddress address, int port})>[
      (address: InternetAddress('255.255.255.255'), port: port),
    ];
    try {
      final ifaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLoopback: false);
      for (final i in ifaces) {
        for (final a in i.addresses) {
          final b = a.rawAddress;
          // Directed broadcast, assuming a /24 like most home networks.
          out.add((
            address: InternetAddress('${b[0]}.${b[1]}.${b[2]}.255'),
            port: port,
          ));
        }
      }
    } on SocketException catch (e) {
      AppLog.w('discovery: interface list failed', e);
    }
    return out;
  }

  Future<void> _send() async {
    final s = _socket;
    if (s == null) return;
    final data = utf8.encode(jsonEncode({
      'm': discoveryMagic,
      'id': deviceId,
      'name': deviceName,
      'port': _httpPort,
      'tlsPort': ?_tlsPort,
      'p': platformName,
    }));
    for (final t in await _targets()) {
      try {
        s.send(data, t.address, t.port);
      } on SocketException catch (e) {
        AppLog.d('discovery: send failed to ${t.address.address}', e);
      }
    }
  }
}
