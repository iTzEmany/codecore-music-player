import 'package:codecore/services/share/net_prefix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('directedBroadcast by prefix', () {
    expect(directedBroadcast([192, 168, 1, 17], 24), '192.168.1.255');
    expect(directedBroadcast([172, 16, 5, 9], 16), '172.16.255.255');
    expect(directedBroadcast([10, 1, 5, 9], 22), '10.1.7.255');
    expect(directedBroadcast([192, 168, 1, 5], 30), '192.168.1.7');
    expect(directedBroadcast([10, 1, 2, 3], 8), '10.255.255.255');
    expect(directedBroadcast([192, 168, 1, 5], 31), isNull);
    expect(directedBroadcast([192, 168, 1, 5], 32), isNull);
    expect(directedBroadcast([10, 0, 0, 1], 7), isNull);
  });

  test('parseIpAddrShow: real output, two interfaces, odd lines', () {
    expect(
        parseIpAddrShow('1: lo    inet 127.0.0.1/8 scope host lo\\       valid_lft forever\n'
            '3: wlp4s0    inet 192.168.1.17/24 brd 192.168.1.255 scope global dynamic noprefixroute wlp4s0\\ valid_lft 1sec\n'),
        {'192.168.1.17': 24});
    expect(
        parseIpAddrShow('2: eth0    inet 10.1.2.3/16 brd 10.1.255.255 scope global eth0\n'
            '4: wlan0    inet 192.168.43.1/24 brd 192.168.43.255 scope global wlan0\n'),
        {'10.1.2.3': 16, '192.168.43.1': 24});
    expect(parseIpAddrShow('garbage\n\n5: x inet 1.2.3.4/99 \n6: y inet6 fe80::1/64\n'), isEmpty);
  });

  test('parseIpAddrShow: peer line skipped, secondary address kept', () {
    expect(
        parseIpAddrShow('5: tun0    inet 100.64.0.2 peer 100.64.0.1/32 scope global tun0\n'
            '2: eth0    inet 10.0.0.2/24 brd 10.0.0.255 scope global eth0\n'
            '2: eth0    inet 10.0.1.2/16 brd 10.0.255.255 scope global secondary eth0\n'),
        {'10.0.0.2': 24, '10.0.1.2': 16});
  });

  test('parseIpAddrShow: a broken line does not hide the others; plain /32 kept', () {
    expect(
        parseIpAddrShow('2: a    inet 10.0.0.1/099999999999999999999 scope global a\n'
            '3: b    inet 10.0.0.2/24 scope global b\n'
            '4: c    inet 100.64.0.2/32 scope global c\n'),
        {'10.0.0.2': 24, '100.64.0.2': 32});
  });

  test('broadcastTargets: implausible known prefix falls back to the guess', () {
    for (final p in [0, 7, -1]) {
      expect(broadcastTargets(['10.0.0.1'], {'10.0.0.1': p}, windows: false), {'10.0.0.255'});
    }
  });

  test('broadcastTargets: known /32 gives no guess', () {
    expect(broadcastTargets(['100.64.0.2'], {'100.64.0.2': 32}, windows: true), isEmpty);
  });

  test('broadcastTargets: real prefix, fallback /24, Windows guess', () {
    expect(broadcastTargets(['10.1.2.3'], {'10.1.2.3': 16}, windows: false), {'10.1.255.255'});
    expect(broadcastTargets(['10.1.2.3'], {}, windows: false), {'10.1.2.255'});
    expect(broadcastTargets(['10.1.2.3'], {}, windows: true), {'10.1.2.255', '10.1.255.255'});
    expect(broadcastTargets(['10.1.2.3', '10.1.2.4'], {'10.1.2.3': 24, '10.1.2.4': 24}, windows: false),
        {'10.1.2.255'});
  });
}
