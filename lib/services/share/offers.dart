import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/app_log.dart';
import '../../core/text_utils.dart';
import 'lan_server.dart';

export 'offer_node.dart' show OfferNode, callerFingerprint, kCallerKey;

const _audioExts = {
  'mp3', 'flac', 'wav', 'ogg', 'oga', 'opus', 'm4a', 'aac', 'aiff', 'aif',
  'wma', 'webm',
};

const maxOfferItems = 500;
const offerTtl = Duration(minutes: 10);

/// True for addresses that can only live on a local network (never the
/// public Internet): RFC1918, link-local and (optionally) loopback.
bool isLocalNetworkAddress(String address, {bool allowLoopback = false}) {
  final a = InternetAddress.tryParse(address);
  if (a == null) return false;
  if (a.isLoopback) return allowLoopback;
  if (a.isLinkLocal) return true;
  final b = a.rawAddress;
  if (a.type == InternetAddressType.IPv4) {
    if (b[0] == 10) return true;
    if (b[0] == 172 && b[1] >= 16 && b[1] <= 31) return true;
    if (b[0] == 192 && b[1] == 168) return true;
    return false;
  }
  return b[0] & 0xFE == 0xFC; // fc00::/7 unique local
}

String newToken([Random? random]) {
  final r = random ?? Random.secure();
  return List.generate(16, (_) => r.nextInt(256))
      .map((v) => v.toRadixString(16).padLeft(2, '0'))
      .join();
}

class OfferItem {
  const OfferItem({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    required this.sizeBytes,
    required this.ext,
  });

  final int id;
  final String title;
  final String? artist, album;
  final int sizeBytes;
  final String ext;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'sizeBytes': sizeBytes,
        'ext': ext,
      };

  /// Strict parsing of untrusted input; returns null for anything odd.
  static OfferItem? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final size = raw['sizeBytes'];
    final ext = raw['ext'];
    final title = raw['title'];
    if (id is! int || size is! int || ext is! String || title is! String) {
      return null;
    }
    final e = ext.toLowerCase();
    if (!_audioExts.contains(e) || size < 0) return null;
    String? clip(Object? v, int max) =>
        v is String ? (v.length > max ? v.substring(0, max) : v) : null;
    return OfferItem(
      id: id,
      title: clip(title, 200) ?? '',
      artist: clip(raw['artist'], 200),
      album: clip(raw['album'], 200),
      sizeBytes: size,
      ext: e,
    );
  }

  /// `Artist - Title`, sanitised; never a path.
  String get baseName => sanitizeFileName(
      artist == null || artist!.isEmpty ? title : '$artist - $title');
}

enum OfferStatus { pending, accepted, declined, cancelled, expired, done, failed }

class IncomingOffer {
  IncomingOffer({
    required this.offerId,
    required this.fromId,
    required this.fromName,
    required this.fromHost,
    required this.fromPort,
    this.fromTlsPort,
    required this.token,
    required this.items,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  final String offerId, fromId, fromName, fromHost, token;
  final int fromPort;

  /// HTTPS port of the sender, when it has one: answers go there.
  final int? fromTlsPort;
  final List<OfferItem> items;
  final DateTime receivedAt;
  OfferStatus status = OfferStatus.pending;
  int received = 0; // files already stored

  int get totalBytes => items.fold(0, (a, b) => a + b.sizeBytes);
}

class OutgoingOffer {
  OutgoingOffer({
    required this.offerId,
    required this.toId,
    required this.toName,
    required this.token,
    required this.entries,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String offerId, toId, toName, token;
  final Map<int, ShareEntry> entries;
  final DateTime createdAt;
  OfferStatus status = OfferStatus.pending;

  bool get open =>
      status == OfferStatus.pending || status == OfferStatus.accepted;
}

/// Offer state plus the HTTP routes both roles need:
/// receiver: `POST /` (new offer), `POST /<id>/cancel`;
/// sender:   `POST /<id>/accept|decline|done`, `GET /<id>/file/<n>`.
/// Mounted under `/offer` by [OfferNode].
class OfferService {
  OfferService({
    required this.deviceId,
    required this.deviceName,
    DateTime Function()? now,
    this.allowLoopback = false,
    this.maxPendingIncoming = 5,
    this.maxOffersPerMinute = 5,
  }) : _now = now ?? DateTime.now;

  final String deviceId, deviceName;
  final bool allowLoopback;
  final int maxPendingIncoming, maxOffersPerMinute;
  final DateTime Function() _now;

  final incoming = <String, IncomingOffer>{};
  final outgoing = <String, OutgoingOffer>{};
  final _changes = StreamController<void>.broadcast();
  final _recent = <String, List<DateTime>>{}; // ip -> offer timestamps

  /// Fired when a new valid offer arrives (the UI asks the user).
  void Function(IncomingOffer offer)? onIncoming;

  Stream<void> get changes => _changes.stream;

  bool get hasOpenOutgoing {
    expire();
    return outgoing.values.any((o) => o.open);
  }

  void notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void dispose() => _changes.close();

  void expire() {
    final limit = _now().subtract(offerTtl);
    for (final o in outgoing.values) {
      if (o.open && o.createdAt.isBefore(limit)) o.status = OfferStatus.expired;
    }
    for (final o in incoming.values) {
      if (o.status == OfferStatus.pending && o.receivedAt.isBefore(limit)) {
        o.status = OfferStatus.expired;
      }
    }
  }

  // ---- sender side -------------------------------------------------------

  OutgoingOffer createOutgoing({
    required String toId,
    required String toName,
    required List<ShareEntry> entries,
  }) {
    final offer = OutgoingOffer(
      offerId: newToken(),
      toId: toId,
      toName: toName,
      token: newToken(),
      entries: {for (final e in entries) e.id: e},
      createdAt: _now(),
    );
    outgoing[offer.offerId] = offer;
    notify();
    return offer;
  }

  Map<String, Object?> offerPayload(OutgoingOffer o, int port, {int? tlsPort}) => {
        'offerId': o.offerId,
        'fromId': deviceId,
        'fromName': deviceName,
        'port': port,
        'tlsPort': ?tlsPort,
        'token': o.token,
        'items': [
          for (final e in o.entries.values)
            OfferItem(
              id: e.id,
              title: e.title,
              artist: e.artist,
              album: e.album,
              sizeBytes: e.sizeBytes,
              ext: e.ext,
            ).toJson(),
        ],
      };

  // ---- HTTP ----------------------------------------------------------------

  String _ip(Request r, String Function(Request)? override) {
    if (override != null) return override(r);
    final info = r.context['shelf.io.connection_info'];
    return info is HttpConnectionInfo ? info.remoteAddress.address : 'unknown';
  }

  bool _tokenOk(String expected, String? given) {
    if (given == null || given.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ given.codeUnitAt(i);
    }
    return diff == 0;
  }

  Router buildRouter({String Function(Request)? clientIp}) {
    final router = Router();

    // Receiver: someone offers files.
    router.post('/', (Request r) async {
      final ip = _ip(r, clientIp);
      if (!isLocalNetworkAddress(ip, allowLoopback: allowLoopback)) {
        AppLog.w('offer: refused non-local $ip');
        return Response.forbidden('local network only');
      }
      expire();
      final times = _recent.putIfAbsent(ip, () => []);
      final cutoff = _now().subtract(const Duration(minutes: 1));
      times.removeWhere((t) => t.isBefore(cutoff));
      final pending =
          incoming.values.where((o) => o.status == OfferStatus.pending).length;
      if (times.length >= maxOffersPerMinute || pending >= maxPendingIncoming) {
        return Response(429, body: 'too many offers');
      }
      Object? body;
      try {
        body = jsonDecode(await r.readAsString());
      } on FormatException {
        return Response(400, body: 'bad json');
      }
      if (body is! Map) return Response(400, body: 'bad request');
      final offerId = body['offerId'], fromId = body['fromId'];
      final fromName = body['fromName'], port = body['port'];
      final token = body['token'], rawItems = body['items'];
      final tlsRaw = body['tlsPort'];
      final tlsPort = tlsRaw is int && tlsRaw > 0 && tlsRaw < 65536 ? tlsRaw : null;
      if (offerId is! String ||
          fromId is! String ||
          fromName is! String ||
          port is! int ||
          token is! String ||
          rawItems is! List ||
          offerId.isEmpty ||
          offerId.length > 64 ||
          token.length < 8 ||
          token.length > 64 ||
          port < 1 ||
          port > 65535 ||
          rawItems.isEmpty ||
          rawItems.length > maxOfferItems) {
        return Response(400, body: 'bad request');
      }
      final items = <OfferItem>[];
      for (final raw in rawItems) {
        final it = OfferItem.tryParse(raw);
        if (it != null) items.add(it);
      }
      if (items.length != rawItems.length) {
        return Response(400, body: 'invalid items');
      }
      if (incoming.containsKey(offerId)) {
        return Response(409, body: 'duplicate');
      }
      times.add(_now());
      final offer = IncomingOffer(
        offerId: offerId,
        fromId: fromId,
        // The name is only a label; it is shown, never trusted.
        fromName: fromName.length > 60 ? fromName.substring(0, 60) : fromName,
        // Where to pull from: the observed address, not a claimed one.
        fromHost: ip,
        fromPort: port,
        fromTlsPort: tlsPort,
        token: token,
        items: items,
        receivedAt: _now(),
      );
      incoming[offerId] = offer;
      notify();
      AppLog.i('offer: ${items.length} items from $ip');
      onIncoming?.call(offer);
      return Response(202,
          body: jsonEncode({'status': 'pending'}),
          headers: {'content-type': 'application/json'});
    });

    // Receiver: the sender withdraws a pending offer.
    router.post('/<id>/cancel', (Request r, String id) {
      final o = incoming[id];
      if (o == null) return Response.notFound('not found');
      if (!_tokenOk(o.token, r.headers['x-token'])) {
        return Response(401, body: 'unauthorized');
      }
      if (o.status == OfferStatus.pending) o.status = OfferStatus.cancelled;
      notify();
      return Response.ok('ok');
    });

    OutgoingOffer? authorised(Request r, String id) {
      final o = outgoing[id];
      if (o == null || !_tokenOk(o.token, r.headers['x-token'])) return null;
      return o;
    }

    // Sender: the receiver answers.
    router.post('/<id>/accept', (Request r, String id) {
      expire();
      final o = authorised(r, id);
      if (o == null) return Response(401, body: 'unauthorized');
      if (o.status != OfferStatus.pending) {
        return Response(409, body: 'not pending');
      }
      o.status = OfferStatus.accepted;
      notify();
      return Response.ok('ok');
    });

    router.post('/<id>/decline', (Request r, String id) {
      final o = authorised(r, id);
      if (o == null) return Response(401, body: 'unauthorized');
      if (o.status == OfferStatus.pending) o.status = OfferStatus.declined;
      notify();
      return Response.ok('ok');
    });

    router.post('/<id>/done', (Request r, String id) {
      final o = authorised(r, id);
      if (o == null) return Response(401, body: 'unauthorized');
      if (o.status == OfferStatus.accepted) o.status = OfferStatus.done;
      notify();
      return Response.ok('ok');
    });

    // Sender: stream one file of an accepted offer.
    router.get('/<id>/file/<n>', (Request r, String id, String n) async {
      expire();
      final o = authorised(r, id);
      if (o == null) return Response(401, body: 'unauthorized');
      if (o.status != OfferStatus.accepted) {
        return Response.forbidden('offer not accepted');
      }
      final itemId = int.tryParse(n);
      final entry = itemId == null ? null : o.entries[itemId];
      if (entry == null) return Response.notFound('not found');
      final file = File(entry.path);
      if (!await file.exists()) return Response.notFound('not found');
      final size = await file.length();
      final range = parseRange(r.headers['range'], size);
      if (identical(range, RangeResult.invalid)) {
        return Response(416, headers: {'content-range': 'bytes */$size'});
      }
      final base = {
        'content-type': 'application/octet-stream',
        'accept-ranges': 'bytes',
      };
      if (range.isFull) {
        return Response.ok(file.openRead(),
            headers: {...base, 'content-length': '$size'});
      }
      return Response(206,
          body: file.openRead(range.start, range.end + 1),
          headers: {
            ...base,
            'content-length': '${range.end - range.start + 1}',
            'content-range': 'bytes ${range.start}-${range.end}/$size',
          });
    });

    return router;
  }
}

/// The HTTP endpoint of this device while discovery/receiving is on.
/// Bound to all interfaces; every route refuses non-local peers.
