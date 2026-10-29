import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/app_log.dart';

const _channel = MethodChannel('codecore/audio');

/// A connected Bluetooth (A2DP) output, as the Android side reports it.
class BluetoothOutput {
  const BluetoothOutput({required this.name, required this.address, this.deviceClass});
  final String name;
  final String address;
  final int? deviceClass;
}

class BluetoothSnapshot {
  const BluetoothSnapshot({this.permission = false, this.outputs = const [], this.ok = true});
  final bool permission;
  final List<BluetoothOutput> outputs;

  /// False when the read itself failed (timeout, error): the list says nothing.
  final bool ok;

  static const empty = BluetoothSnapshot();

  /// Tolerant: missing fields or wrong types give the empty value.
  factory BluetoothSnapshot.parse(Object? raw) {
    if (raw is! Map) return empty;
    final outputs = <BluetoothOutput>[];
    final list = raw['outputs'];
    if (list is List) {
      for (final o in list) {
        if (o is! Map) continue;
        final address = o['address'];
        if (address is! String) continue;
        final name = o['name'];
        final cls = o['deviceClass'];
        outputs.add(BluetoothOutput(
          name: name is String ? name : address,
          address: address,
          deviceClass: cls is int ? cls : null,
        ));
      }
    }
    return BluetoothSnapshot(permission: raw['permission'] == true, outputs: outputs, ok: raw['ok'] != false);
  }
}

bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

final _changed = StreamController<void>.broadcast();
final _seen = StreamController<void>.broadcast();

/// A Bluetooth A2DP connection changed (the list may be different now).
Stream<void> get bluetoothChanged => _changed.stream;

/// A Bluetooth output showed up (needs no permission).
Stream<void> get bluetoothOutputSeen => _seen.stream;

/// Called by the single `codecore/audio` handler (see output_route.dart).
/// Returns true when the call was a Bluetooth event.
bool handleBluetoothCall(String method) {
  switch (method) {
    case 'bluetoothChanged':
      _changed.add(null);
      return true;
    case 'bluetoothOutputSeen':
      _seen.add(null);
      return true;
  }
  return false;
}

Future<BluetoothSnapshot> fetchBluetoothOutputs() async {
  if (!_android) return BluetoothSnapshot.empty;
  try {
    return BluetoothSnapshot.parse(await _channel.invokeMethod<Object>('bluetoothOutputs'));
  } catch (e, st) {
    AppLog.w('bluetooth outputs unavailable', e, st);
    return const BluetoothSnapshot(ok: false);
  }
}

Future<bool> requestBluetoothPermission() => _bool('requestBluetoothPermission');

Future<bool> bluetoothPermission() => _bool('bluetoothPermission');

/// A Bluetooth A2DP output is active now (needs no permission).
Future<bool> bluetoothOutputActive() => _bool('bluetoothOutputActive');

Future<bool> _bool(String method) async {
  if (!_android) return false;
  try {
    return await _channel.invokeMethod<bool>(method) ?? false;
  } catch (e, st) {
    AppLog.w('bluetooth $method failed', e, st);
    return false;
  }
}
