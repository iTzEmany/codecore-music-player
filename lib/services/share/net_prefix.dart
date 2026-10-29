import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/app_log.dart';

/// Directed-broadcast address of [ipv4]/[prefix]; null when the network has
/// none (/31, /32) or the prefix is implausible (< 8).
String? directedBroadcast(List<int> ipv4, int prefix) {
  if (ipv4.length != 4 || prefix < 8 || prefix >= 31) return null;
  final ip = (ipv4[0] << 24) | (ipv4[1] << 16) | (ipv4[2] << 8) | ipv4[3];
  final host = 0xFFFFFFFF >> prefix;
  final b = ip | host;
  return '${(b >> 24) & 255}.${(b >> 16) & 255}.${(b >> 8) & 255}.${b & 255}';
}

/// Parses `ip -o -4 addr show`: address -> prefix length. Skips `lo` and any
/// line that is not `<n>: <iface> inet a.b.c.d/p ...`.
Map<String, int> parseIpAddrShow(String out) {
  final res = <String, int>{};
  final re = RegExp(r'^\d+:\s+(\S+)\s+inet\s+(\d+\.\d+\.\d+\.\d+)/(\d+)\b');
  for (final line in out.split('\n')) {
    final m = re.firstMatch(line.trim());
    if (m == null || m[1] == 'lo') continue;
    final p = int.tryParse(m[3]!);
    if (p == null || p > 32) continue;
    res[m[2]!] = p;
  }
  return res;
}

/// Broadcast targets for [addresses] (dotted IPv4): the real directed
/// broadcast where a prefix is known, else a guess: Windows `a.b.c.255` plus
/// `a.b.255.255`, elsewhere the /24.
Set<String> broadcastTargets(
  Iterable<String> addresses,
  Map<String, int> prefixes, {
  required bool windows,
}) {
  final out = <String>{};
  for (final a in addresses) {
    final b = a.split('.').map(int.parse).toList();
    final known = prefixes[a];
    if (known != null && known >= 8) {
      // Known prefix: /31 and /32 (VPNs) have no broadcast, so no guess either.
      final real = directedBroadcast(b, known);
      if (real != null) out.add(real);
      continue;
    }
    out.add('${b[0]}.${b[1]}.${b[2]}.255');
    if (windows) out.add('${b[0]}.${b[1]}.255.255');
  }
  return out;
}

/// Reads address -> prefix for the local interfaces; empty when unavailable.
Future<Map<String, int>> readNetPrefixes() async {
  try {
    if (Platform.isAndroid) {
      final raw = await const MethodChannel('codecore/audio')
          .invokeMethod<List<Object?>>('netPrefix');
      return {
        for (final e in raw ?? const [])
          if (e is Map && e['address'] is String && e['prefix'] is int)
            e['address'] as String: e['prefix'] as int,
      };
    }
    if (Platform.isLinux) {
      final p = await Process.start('ip', ['-o', '-4', 'addr', 'show']);
      final out = p.stdout.transform(utf8.decoder).join();
      p.stderr.drain<void>();
      try {
        if (await p.exitCode.timeout(const Duration(seconds: 2)) == 0) {
          return parseIpAddrShow(await out);
        }
      } on TimeoutException {
        p.kill();
        AppLog.w('net prefix: ip timed out');
      }
    }
  } catch (e, st) {
    AppLog.w('net prefix unavailable', e, st);
  }
  return {};
}
