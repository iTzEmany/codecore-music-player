import 'package:codecore/services/share/share_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the link a share shows is read back', () {
    final l = parseShareLink('http://192.168.1.20:4567/?pin=123456')!;
    expect((l.host, l.port, l.pin), ('192.168.1.20', 4567, '123456'));
    expect(l.toString(), 'http://192.168.1.20:4567/?pin=123456');
    expect(parseShareLink('  http://10.0.0.5:8080/?pin=000001\n')!.pin, '000001');
  });

  test('anything else is ignored: other schemes, public hosts, no PIN, a short PIN, no port, junk', () {
    for (final bad in [
      'https://192.168.1.20:4567/?pin=123456',
      'http://example.com:4567/?pin=123456',
      'http://8.8.8.8:4567/?pin=123456',
      'http://192.168.1.20:4567/',
      'http://192.168.1.20:4567/?pin=12345',
      'http://192.168.1.20:4567/?pin=abcdef',
      'http://192.168.1.20/?pin=123456',
      'hello world',
      '',
      'codecore://pair?x=1',
    ]) {
      expect(parseShareLink(bad), isNull, reason: bad);
    }
  });

  test('loopback only when asked (tests)', () {
    expect(parseShareLink('http://127.0.0.1:4000/?pin=123456'), isNull);
    expect(parseShareLink('http://127.0.0.1:4000/?pin=123456', allowLoopback: true), isNotNull);
  });
}
