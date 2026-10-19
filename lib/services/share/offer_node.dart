import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import '../../core/app_log.dart';
import 'device_identity.dart';
import 'offers.dart' show OfferService, isLocalNetworkAddress;
import 'request_signing.dart';

/// The HTTP(S) endpoint of a device: `/hello`, `/offer`, and (over HTTPS only)
/// the pairing and sync routes. Plain HTTP stays for older versions and the Jam.
class OfferNode {
  OfferNode(
    this.service, {
    this.allowLoopback = false,
    this.extraRoutes = const {},
    this.identity,
    this.secureRoutes = const {},
  });

  final OfferService service;

  /// Extra routers mounted by prefix (e.g. `/jam`), behind the same filter.
  /// They are served on the plain HTTP port only (R61: players cannot check a
  /// self-signed certificate).
  final Map<String, Handler> extraRoutes;

  /// Routers served only over HTTPS (`/pair`, `/sync`).
  final Map<String, Handler> secureRoutes;

  /// With an identity the node also listens over HTTPS; without it (the
  /// certificate could not be made) it is plain HTTP as before.
  final DeviceIdentity? identity;
  final bool allowLoopback;
  HttpServer? _server, _secure;

  bool get running => _server != null;

  /// The plain HTTP port: offers from older versions, files and the Jam.
  int? get port => _server?.port;

  /// The HTTPS port; null without an identity.
  int? get tlsPort => _secure?.port;

  Router _root({required bool secure}) {
    final root = Router();
    root.get('/hello', (Request r) => Response.ok(
          jsonEncode({
            'app': 'codecore',
            'id': service.deviceId,
            'name': service.deviceName,
            'v': identity == null ? 2 : 3,
            'tlsPort': ?tlsPort,
            'fingerprint': ?identity?.fingerprint,
          }),
          headers: {'content-type': 'application/json'},
        ));
    root.mount('/offer', service.buildRouter().call);
    if (secure) {
      secureRoutes.forEach(root.mount);
    } else {
      extraRoutes.forEach(root.mount);
    }
    return root;
  }

  Handler _pipeline(Router root) => const Pipeline()
      .addMiddleware(_localOnly(allowLoopback))
      .addMiddleware(_signedCaller())
      .addHandler(root.call);

  Future<int> start() async {
    if (_server != null) return _server!.port;
    final id = identity;
    if (id != null) {
      // Opened first: the plain server's /hello announces this port.
      _secure = await HttpServer.bindSecure(InternetAddress.anyIPv4, 0, id.context());
      io.serveRequests(_secure!, _pipeline(_root(secure: true)));
    }
    _server = await io.serve(_pipeline(_root(secure: false)), InternetAddress.anyIPv4, 0);
    AppLog.i('offers: listening on ${_server!.port}${tlsPort == null ? '' : ' (https $tlsPort)'}');
    return _server!.port;
  }

  Future<void> stop() async {
    final s = _server, t = _secure;
    _server = null;
    _secure = null;
    await s?.close(force: true);
    await t?.close(force: true);
  }

  /// When the request is signed (`request_signing.dart`) and the signature
  /// holds, the signer's fingerprint goes into the context.
  static Middleware _signedCaller() => (inner) => (r) async {
        if (!r.headers.containsKey(kSigHeader)) return inner(r);
        final bytes = <int>[];
        await for (final chunk in r.read()) {
          bytes.addAll(chunk);
          if (bytes.length > 1024 * 1024) return Response(413, body: 'too large');
        }
        final caller = verifyRequest(r.headers, r.method, '/${r.url.path}', bytes);
        return inner(r.change(body: bytes, context: {kCallerKey: ?caller}));
      };

  static Middleware _localOnly(bool allowLoopback) => (inner) => (r) {
        final info = r.context['shelf.io.connection_info'];
        final ip =
            info is HttpConnectionInfo ? info.remoteAddress.address : null;
        if (ip == null || !isLocalNetworkAddress(ip, allowLoopback: allowLoopback)) {
          return Response.forbidden('local network only');
        }
        return inner(r);
      };
}

/// Context key: the fingerprint proven by a valid signature.
const kCallerKey = 'codecore.caller';

/// Who proved they sent [r] (a certificate fingerprint), or null.
String? callerFingerprint(Request r) => r.context[kCallerKey] as String?;
