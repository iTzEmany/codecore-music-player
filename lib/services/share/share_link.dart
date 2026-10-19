import 'offers.dart' show isLocalNetworkAddress;

/// What a Codecore QR code carries: where the other device listens and the PIN
/// of its current share (`http://192.168.1.20:4567/?pin=123456`).
class ShareLink {
  const ShareLink(this.host, this.port, this.pin);

  final String host;
  final int port;
  final String pin;

  @override
  String toString() => 'http://$host:$port/?pin=$pin';
}

/// Reads a scanned text. Anything that is not such a link, or points outside
/// the local network, or has no 6-digit PIN, is null: a QR code on a poster
/// must not make the app connect anywhere.
ShareLink? parseShareLink(String text, {bool allowLoopback = false}) {
  final uri = Uri.tryParse(text.trim());
  if (uri == null || uri.scheme != 'http' || !uri.hasPort) return null;
  final pin = uri.queryParameters['pin'];
  if (pin == null || !RegExp(r'^\d{6}$').hasMatch(pin)) return null;
  if (!isLocalNetworkAddress(uri.host, allowLoopback: allowLoopback)) return null;
  return ShareLink(uri.host, uri.port, pin);
}
