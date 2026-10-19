import 'dart:io';

import '../services/share/device_identity.dart';
import '../core/paths.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart' as p;

import '../core/app_log.dart';
import '../data/db/app_database.dart';
import '../services/share/lan_client.dart';
import '../services/share/lan_server.dart';
import '../services/share/trusted_devices.dart';
import 'database_providers.dart';
import 'library_providers.dart';
import 'settings_providers.dart';

final lanClientProvider = Provider<LanClient>((ref) => LanClient());

final lanServerProvider = Provider<LanServer>((ref) {
  final s = LanServer();
  ref.onDispose(s.stop);
  return s;
});

/// Name the OS gives the device (overridden at start-up on Android, where the
/// hostname is just "localhost").
final systemDeviceNameProvider = Provider<String>(
  (ref) => Platform.localHostname,
);

final deviceNameProvider = Provider<String>((ref) {
  final custom = ref.watch(settingsProvider.select((s) => s.deviceName));
  if (custom != null && custom.trim().isNotEmpty) return custom.trim();
  final system = ref.watch(systemDeviceNameProvider).trim();
  return system.isEmpty || system == 'localhost' ? 'Codecore' : system;
});

/// Local LAN address: the Wi-Fi IP when the OS reports it, otherwise the
/// first non-loopback IPv4 interface.
Future<String?> localIpAddress() async {
  try {
    final wifi = await NetworkInfo().getWifiIP();
    if (wifi != null && wifi.isNotEmpty) return wifi;
  } on Object catch (e, st) {
    AppLog.w('wifi ip lookup failed', e, st);
  }
  final ifaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );
  for (final i in ifaces) {
    for (final a in i.addresses) {
      if (!a.isLoopback) return a.address;
    }
  }
  return null;
}

/// Tracks -> shareable entries (paths stay on this side of the connection).
Future<List<ShareEntry>> buildShareEntries(Ref ref, List<Track> tracks) async {
  final dir = ref.read(coversDirProvider);
  String? coverPath(Track t) {
    final k = t.coverKey;
    if (k == null) return null;
    for (final ext in const ['jpg', 'png']) {
      final f = File(p.join(dir.path, '$k.$ext'));
      if (f.existsSync()) return f.path;
    }
    return null;
  }

  return [
    for (final t in tracks)
      if (!t.missing)
        ShareEntry(
          id: t.id,
          path: t.path,
          title: t.title,
          artist: t.artist,
          album: t.album,
          sizeBytes: t.sizeBytes,
          durationMs: t.durationMs,
          ext: t.format,
          coverPath: coverPath(t),
        ),
  ];
}

class ShareController {
  ShareController(this._ref);

  final Ref _ref;

  Future<ShareInfo?> startSharing(List<int>? ids) async {
    final repo = _ref.read(trackRepositoryProvider);
    final tracks = ids == null
        ? await repo.watchTracks().first
        : await repo.getByIds(ids);
    final entries = await buildShareEntries(_ref, tracks);
    final host = await localIpAddress();
    if (host == null) return null;
    return _ref
        .read(lanServerProvider)
        .start(
          entries: entries,
          host: host,
          deviceName: _ref.read(deviceNameProvider),
        );
  }

  Future<void> stopSharing() => _ref.read(lanServerProvider).stop();
}

final shareControllerProvider = Provider<ShareController>(
  (ref) => ShareController(ref),
);


/// The devices the user paired with, saved on every change.
class TrustedDevicesNotifier extends Notifier<TrustedDevices> {
  @override
  TrustedDevices build() =>
      TrustedDevices.decode(ref.read(settingsStoreProvider).readTrustedDevicesRaw());

  void _set(TrustedDevices next) {
    state = next;
    ref.read(settingsStoreProvider).writeTrustedDevicesRaw(next.encode()).catchError(
      (Object e, StackTrace st) {
        AppLog.w('could not save the trusted devices', e, st);
      },
    );
  }

  void add(TrustedDevice device) => _set(state.add(device));

  void revoke(String id) => _set(state.revoke(id));

  void setAutoAccept(String id, bool value) => _set(state.setAutoAccept(id, value));
}

final trustedDevicesProvider =
    NotifierProvider<TrustedDevicesNotifier, TrustedDevices>(TrustedDevicesNotifier.new);

/// This device's identity (made on first use); null if it could not be made.
final ownIdentityProvider = FutureProvider<DeviceIdentity?>((ref) async {
  try {
    return await DeviceIdentity.loadOrCreate(Directory(await appSupportDir()));
  } on Object catch (e, st) {
    AppLog.w('no device identity', e, st);
    return null;
  }
}, retry: (_, _) => null);
