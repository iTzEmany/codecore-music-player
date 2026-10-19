import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:path/path.dart' as p;

import '../../core/text_utils.dart';
import '../online/youtube_service.dart' show DownloadProgress, uniquePath;
import 'device_identity.dart';
import 'offers.dart' show OfferItem;
import 'request_signing.dart';

class RemoteInfo {
  const RemoteInfo(this.name, {this.tlsPort, this.fingerprint});

  final String name;

  /// Set when the device answers over HTTPS too (version 3).
  final int? tlsPort;
  final String? fingerprint;
}

class RemoteTrack {
  const RemoteTrack({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    required this.sizeBytes,
    required this.durationMs,
    required this.ext,
  });

  factory RemoteTrack.fromJson(Map<String, dynamic> j) => RemoteTrack(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String?,
        album: j['album'] as String?,
        sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
        durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
        ext: j['ext'] as String? ?? 'mp3',
      );

  final int id;
  final String title;
  final String? artist, album;
  final int sizeBytes, durationMs;
  final String ext;

  /// `Artist - Title` (sanitised); used for the received file name.
  String get baseName => sanitizeFileName(
      artist == null || artist!.isEmpty ? title : '$artist - $title');
}

enum LanError { unreachable, wrongPin, blocked, notCodecore, failed, identityChanged }

class LanException implements Exception {
  const LanException(this.error);

  final LanError error;

  @override
  String toString() => 'LanException($error)';
}

/// The handshake failed because the certificate was not the pinned one.
bool _isCertificateRefusal(DioException e) =>
    e.type == DioExceptionType.badCertificate || e.error is HandshakeException || e.error is TlsException;

/// The answer to a [LanClient.securePost], with the certificate the server
/// really presented.
class SecureReply {
  const SecureReply(this.status, this.json, this.seenFingerprint);

  final int status;
  final Map<String, dynamic>? json;
  final String? seenFingerprint;
}

class LanClient {
  LanClient({Dio? dio, this.identity})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 30),
              validateStatus: (_) => true,
            ));

  final Dio _dio;

  /// Signs the requests sent over HTTPS (so the receiver knows who calls). Set
  /// once the identity has been loaded.
  DeviceIdentity? identity;

  /// A client for HTTPS: the certificate is accepted if it hashes to [pin]; with
  /// no pin (a device not paired) any is accepted, the call is «unverified».
  Dio _secureDio(String? pin) {
    final dio = Dio(_dio.options.copyWith());
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..badCertificateCallback = (cert, host, port) =>
            pin == null || DeviceIdentity.fingerprintOfDer(cert.der) == pin,
    );
    return dio;
  }

  /// A signed JSON POST over HTTPS that also reports which certificate the
  /// server showed. Used by pairing, where the first call has no pin yet.
  Future<SecureReply> securePost(String host, int tlsPort, String path, Map<String, Object?> body,
      {String? pin}) async {
    String? seen;
    final dio = Dio(_dio.options.copyWith());
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..badCertificateCallback = (cert, h, p) {
          seen = DeviceIdentity.fingerprintOfDer(cert.der);
          return pin == null || seen == pin;
        },
    );
    final text = jsonEncode(body);
    final id = identity;
    try {
      final r = await dio.post<Object?>('https://$host:$tlsPort$path',
          data: text,
          options: Options(
            contentType: 'application/json',
            headers: {if (id != null) ...signRequest(id, 'POST', path, utf8.encode(text))},
          ));
      final data = r.data;
      return SecureReply(r.statusCode ?? 0, data is Map<String, dynamic> ? data : null, seen);
    } on DioException catch (e) {
      if (pin != null && _isCertificateRefusal(e)) throw const LanException(LanError.identityChanged);
      throw const LanException(LanError.unreachable);
    } finally {
      dio.close(force: true);
    }
  }

  /// `https` when the peer has a [tlsPort], else the plain `http` it always had.
  Future<Response<Object?>> _post(
    String host,
    int port,
    int? tlsPort,
    String? pin,
    String path,
    String? body, {
    Map<String, String> headers = const {},
  }) async {
    final secure = tlsPort != null;
    final dio = secure ? _secureDio(pin) : _dio;
    final bytes = body == null ? const <int>[] : utf8.encode(body);
    final id = identity;
    try {
      return await dio.post<Object?>(
        '${secure ? 'https' : 'http'}://$host:${secure ? tlsPort : port}$path',
        data: body,
        options: Options(
          contentType: body == null ? null : 'application/json',
          headers: {...headers, if (secure && id != null) ...signRequest(id, 'POST', path, bytes)},
        ),
      );
    } on DioException catch (e) {
      if (secure && pin != null && _isCertificateRefusal(e)) {
        throw const LanException(LanError.identityChanged);
      }
      throw const LanException(LanError.unreachable);
    }
  }

  /// Accepts `host:port`, optionally with a `http://` prefix.
  static ({String host, int port})? parseAddress(String input) {
    var s = input.trim();
    s = s.replaceFirst(RegExp(r'^https?://'), '');
    s = s.split('/').first;
    final i = s.lastIndexOf(':');
    if (i <= 0) return null;
    final port = int.tryParse(s.substring(i + 1));
    final host = s.substring(0, i);
    if (port == null || port < 1 || port > 65535 || host.isEmpty) return null;
    return (host: host, port: port);
  }

  Options _options(String? pin, {ResponseType? type}) => Options(
        headers: {'X-Pin': ?pin},
        responseType: type,
      );

  Never _fail(Response<dynamic> r) {
    if (r.statusCode == 401) throw const LanException(LanError.wrongPin);
    if (r.statusCode == 429) throw const LanException(LanError.blocked);
    throw const LanException(LanError.failed);
  }

  Future<RemoteInfo> hello(String host, int port, {CancelToken? cancel}) async {
    try {
      final r = await _dio.get<Object?>('http://$host:$port/hello',
          cancelToken: cancel);
      final data = r.data;
      if (r.statusCode != 200 || data is! Map || data['app'] != 'codecore') {
        throw const LanException(LanError.notCodecore);
      }
      final tls = data['tlsPort'];
      return RemoteInfo(
        '${data['name'] ?? host}',
        tlsPort: tls is int && tls > 0 && tls < 65536 ? tls : null,
        fingerprint: data['fingerprint'] is String ? data['fingerprint'] as String : null,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw const LanException(LanError.unreachable);
    }
  }

  /// The same `/hello` over HTTPS: what the certificate really is, checked
  /// against [pin] when there is one.
  Future<RemoteInfo> helloSecure(String host, int tlsPort, {String? pin}) async {
    String? seen;
    final dio = Dio(_dio.options.copyWith());
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..badCertificateCallback = (cert, h, p) {
          seen = DeviceIdentity.fingerprintOfDer(cert.der);
          return pin == null || seen == pin;
        },
    );
    try {
      final r = await dio.get<Object?>('https://$host:$tlsPort/hello');
      final data = r.data;
      if (r.statusCode != 200 || data is! Map || data['app'] != 'codecore') {
        throw const LanException(LanError.notCodecore);
      }
      return RemoteInfo('${data['name'] ?? host}', tlsPort: tlsPort, fingerprint: seen);
    } on DioException catch (e) {
      if (pin != null && _isCertificateRefusal(e)) {
        throw const LanException(LanError.identityChanged);
      }
      throw const LanException(LanError.unreachable);
    }
  }

  Future<List<RemoteTrack>> manifest(String host, int port, String pin,
      {CancelToken? cancel}) async {
    try {
      final r = await _dio.get<Object?>('http://$host:$port/manifest',
          options: _options(pin), cancelToken: cancel);
      if (r.statusCode != 200) _fail(r);
      final data = r.data;
      if (data is! List) throw const LanException(LanError.failed);
      return [
        for (final e in data)
          if (e is Map<String, dynamic>) RemoteTrack.fromJson(e),
      ];
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw const LanException(LanError.unreachable);
    }
  }

  /// Writes `<name>.<ext>.part`, checks the length, then renames. The final
  /// event carries the path. On cancel or error nothing is left behind.
  Stream<DownloadProgress> download(
    String host,
    int port,
    String pin,
    RemoteTrack track,
    Directory outDir, {
    CancelToken? cancel,
  }) =>
      _fetch(
        url: 'http://$host:$port/file/${track.id}',
        headers: {'X-Pin': pin},
        baseName: track.baseName,
        ext: track.ext,
        fallbackSize: track.sizeBytes,
        outDir: outDir,
        cancel: cancel,
      );

  /// Pulls one file of an accepted offer from the sender.
  Stream<DownloadProgress> downloadOfferItem(
    String host,
    int port,
    String offerId,
    String token,
    OfferItem item,
    Directory outDir, {
    CancelToken? cancel,
  }) =>
      _fetch(
        url: 'http://$host:$port/offer/$offerId/file/${item.id}',
        headers: {'X-Token': token},
        baseName: item.baseName,
        ext: item.ext,
        fallbackSize: item.sizeBytes,
        outDir: outDir,
        cancel: cancel,
      );

  /// Delivers an offer (metadata only) to a receiver; it stays pending there.
  /// Over HTTPS (signed) when the peer has a [tlsPort]; [pin] is the
  /// fingerprint saved for it, if it is paired.
  Future<void> sendOffer(String host, int port, Map<String, Object?> payload,
      {int? tlsPort, String? pin}) async {
    final r = await _post(host, port, tlsPort, pin, '/offer/', jsonEncode(payload));
    if (r.statusCode == 202) return;
    if (r.statusCode == 429) throw const LanException(LanError.blocked);
    throw const LanException(LanError.failed);
  }

  /// `accept`, `decline` or `done` towards the sender; `cancel` towards the
  /// receiver. All authenticated by the offer token.
  Future<void> offerAction(String host, int port, String offerId,
      String action, String token,
      {int? tlsPort, String? pin}) async {
    final r = await _post(host, port, tlsPort, pin, '/offer/$offerId/$action', null,
        headers: {'X-Token': token});
    if (r.statusCode != 200) throw const LanException(LanError.failed);
  }

  Stream<DownloadProgress> _fetch({
    required String url,
    required Map<String, String> headers,
    required String baseName,
    required String ext,
    required int fallbackSize,
    required Directory outDir,
    CancelToken? cancel,
  }) async* {
    await outDir.create(recursive: true);
    final target =
        uniquePath(outDir.path, baseName, ext, (f) => File(f).existsSync());
    final part = File('$target.part');
    IOSink? sink;
    try {
      final r = await _dio.get<ResponseBody>(
        url,
        options: Options(headers: headers, responseType: ResponseType.stream),
        cancelToken: cancel,
      );
      if (r.statusCode != 200) _fail(r);
      final body = r.data!;
      final expected =
          int.tryParse(r.headers.value(Headers.contentLengthHeader) ?? '') ??
              fallbackSize;
      sink = part.openWrite();
      var received = 0;
      await for (final chunk in body.stream) {
        if (cancel?.isCancelled ?? false) break;
        sink.add(chunk);
        received += chunk.length;
        yield DownloadProgress(received: received, total: expected);
      }
      await sink.close();
      sink = null;
      if (cancel?.isCancelled ?? false) {
        await _deleteQuiet(part);
        return;
      }
      if (received != expected) {
        await _deleteQuiet(part);
        throw const LanException(LanError.failed);
      }
      await part.rename(target);
      yield DownloadProgress(received: received, total: expected, path: target);
    } on DioException catch (e) {
      await sink?.close();
      await _deleteQuiet(part);
      if (CancelToken.isCancel(e)) return;
      throw const LanException(LanError.unreachable);
    } on Object {
      await sink?.close();
      await _deleteQuiet(part);
      rethrow;
    }
  }

  Future<void> _deleteQuiet(File f) async {
    if (await f.exists()) await f.delete();
  }

  static String fileNameOf(String path) => p.basename(path);
}
