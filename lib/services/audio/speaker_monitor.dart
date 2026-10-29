import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_log.dart';
import 'bluetooth_outputs.dart';

/// Guess from the Bluetooth class (D-212). The values are those of
/// `android.bluetooth.BluetoothClass.Device`: major AUDIO_VIDEO (0x0400) plus
/// LOUDSPEAKER 0x0414, PORTABLE_AUDIO 0x041C and HIFI_AUDIO 0x0428 mean a
/// speaker; WEARABLE_HEADSET 0x0404, HANDSFREE 0x0408, HEADPHONES 0x0418,
/// CAR_AUDIO 0x0420 and no class at all do not.
const _speakerClasses = {0x0414, 0x041C, 0x0428};

bool estimateSpeaker(int? deviceClass) => _speakerClasses.contains(deviceClass);

/// The user's answer to «È una cassa?» for one device.
class SpeakerAnswer {
  const SpeakerAnswer({required this.name, required this.isSpeaker});
  final String name;
  final bool isSpeaker;
}

/// What the UI should ask next.
sealed class SpeakerPrompt {
  const SpeakerPrompt();
}

/// First Bluetooth output seen and the permission was never asked.
class PermissionPrompt extends SpeakerPrompt {
  const PermissionPrompt();
}

/// A connected device without an answer.
class AskPrompt extends SpeakerPrompt {
  const AskPrompt(this.output);
  final BluetoothOutput output;
}

/// Which connected Bluetooth output is a speaker: the guess from its class,
/// the answers of the user (per address, in shared_preferences), the master
/// switch and the permission flow. Pure: the platform side is injected.
/// Inert on desktop, where the snapshot is always empty.
class SpeakerMonitor {
  SpeakerMonitor({
    Future<SharedPreferences> Function()? prefs,
    Future<BluetoothSnapshot> Function()? fetch,
    Stream<void>? changed,
    Stream<void>? seen,
    Future<bool> Function()? request,
    Future<bool> Function()? active,
    this.retryDelay = const Duration(seconds: 2),
  })  : _open = prefs ?? SharedPreferences.getInstance,
        _fetch = fetch ?? fetchBluetoothOutputs,
        _changed = changed ?? bluetoothChanged,
        _seen = seen ?? bluetoothOutputSeen,
        _request = request ?? requestBluetoothPermission,
        _active = active ?? bluetoothOutputActive;

  static const _kEnabled = 'speakerJam.enabled';
  static const _kAsked = 'speakerJam.permissionAsked';
  static const _kAnswers = 'speakerJam.answers';

  final Future<SharedPreferences> Function() _open;
  final Future<BluetoothSnapshot> Function() _fetch;
  final Stream<void> _changed;
  final Stream<void> _seen;
  final Future<bool> Function() _request;
  final Future<bool> Function() _active;
  /// Wait before the single retry of a failed read.
  final Duration retryDelay;
  Timer? _retry;

  SharedPreferences? _prefs;
  final _answers = <String, SpeakerAnswer>{};
  final _prompted = <String>{};
  final _pending = <SpeakerPrompt>[];
  var _enabled = true;
  var _asked = false;
  var _disposed = false;
  final _dismissed = <String>{};
  var _permissionPrompted = false;
  var _snapshot = BluetoothSnapshot.empty;
  var _connected = false;
  final _subs = <StreamSubscription<void>>[];
  final _connectedCtrl = StreamController<bool>.broadcast();
  final _promptCtrl = StreamController<SpeakerPrompt>.broadcast();
  final _changesCtrl = StreamController<void>.broadcast();

  bool get connected => _connected;
  bool get enabled => _enabled;
  bool get permissionAsked => _asked;
  bool get permission => _snapshot.permission;
  List<BluetoothOutput> get outputs => _snapshot.outputs;
  Map<String, SpeakerAnswer> get answers => Map.unmodifiable(_answers);

  /// Emits only when [connected] changes.
  Stream<bool> get speakerConnected => _connectedCtrl.stream;
  /// Prompts raised while nobody listened are delivered, once, to the next listener.
  Stream<SpeakerPrompt> get prompts => Stream.multi((c) {
        for (final p in _pending) {
          c.add(p);
        }
        _pending.clear();
        final sub = _promptCtrl.stream.listen(c.add);
        c.onCancel = sub.cancel;
      }, isBroadcast: true);

  /// Raised and not yet delivered to any listener.
  List<SpeakerPrompt> get pending => List.unmodifiable(_pending);

  void _raise(SpeakerPrompt p) => _promptCtrl.hasListener ? _promptCtrl.add(p) : _pending.add(p);

  /// Anything the settings show may have changed.
  Stream<void> get changes => _changesCtrl.stream;

  /// Loads the saved facts, starts listening and reads the connected outputs.
  Future<void> start() async {
    try {
      final p = _prefs = await _open();
      _enabled = p.getBool(_kEnabled) ?? true;
      _asked = p.getBool(_kAsked) ?? false;
      final raw = p.getString(_kAnswers);
      if (raw != null) {
        (jsonDecode(raw) as Map<String, dynamic>).forEach((a, v) {
          final m = v as Map<String, dynamic>;
          _answers[a] = SpeakerAnswer(name: m['n'] as String, isSpeaker: m['s'] as bool);
        });
      }
    } on Object catch (e, st) {
      AppLog.w('speaker prefs unreadable', e, st);
    }
    _subs
      ..add(_changed.listen((_) => _read()))
      ..add(_seen.listen((_) => _onSeen()));
    await _read();
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _connectedCtrl.close();
    _promptCtrl.close();
    _changesCtrl.close();
  }

  /// An opening of the app (and start): reads the connected outputs and asks
  /// again about the devices whose question was dismissed without an answer.
  Future<void> refresh() {
    _prompted.removeAll(_dismissed);
    _dismissed.clear();
    return _read();
  }

  /// The «È una cassa?» sheet for [address] closed with no answer.
  void dismissed(String address) {
    if (!_answers.containsKey(address)) _dismissed.add(address);
  }

  var _readGen = 0;
  var _appliedGen = 0;

  Future<void> _read({bool retry = true}) async {
    final gen = ++_readGen;
    final snap = await _fetch();
    // Only a result older than one already applied is stale.
    if (_disposed || gen < _appliedGen) return;
    if (snap.ok) {
      _appliedGen = gen;
      _snapshot = snap;
    } else {
      // A failed read says nothing: keep the last outputs, try once more soon.
      AppLog.w('speaker: outputs read failed, keeping the last state');
      if (retry) {
        _retry?.cancel();
        _retry = Timer(retryDelay, () => _read(retry: false));
      }
    }
    final linked = {for (final o in _snapshot.outputs) o.address};
    _prompted.retainAll(linked); // gone and back: ask again if still unanswered
    final now = _snapshot.outputs.any(
      (o) => _answers[o.address]?.isSpeaker ?? estimateSpeaker(o.deviceClass),
    );
    if (now != _connected) {
      _connected = now;
      _connectedCtrl.add(now);
    }
    for (final o in _snapshot.outputs) {
      if (!_answers.containsKey(o.address) && _prompted.add(o.address)) {
        _raise(AskPrompt(o));
      }
    }
    // The «seen» event can be lost at launch: an active output tells the same.
    if (!_snapshot.permission && await _active() && !_disposed) _offerPermission();
    if (_disposed) return;
    _changesCtrl.add(null);
  }

  Future<void> _onSeen() async {
    final snap = await _fetch();
    if (!_disposed && !snap.permission) _offerPermission();
  }

  void _offerPermission() {
    if (_asked || _permissionPrompted) return;
    _permissionPrompted = true;
    _raise(const PermissionPrompt());
  }

  /// «Consenti»: asks the system; either way it is never offered again by itself.
  Future<bool> askPermission() async {
    final granted = await _request();
    await _setAsked();
    await _read();
    return granted;
  }

  /// «Non ora».
  Future<void> declinePermission() async {
    await _setAsked();
    _changesCtrl.add(null);
  }

  Future<void> _setAsked() async {
    _asked = true;
    await _save((p) => p.setBool(_kAsked, true));
  }

  Future<void> answer(String address, bool isSpeaker, {String? name}) async {
    final known = name ?? _answers[address]?.name ?? _nameOf(address) ?? address;
    _answers[address] = SpeakerAnswer(name: known, isSpeaker: isSpeaker);
    await _save((p) => p.setString(
          _kAnswers,
          jsonEncode({
            for (final e in _answers.entries) e.key: {'n': e.value.name, 's': e.value.isSpeaker},
          }),
        ));
    await _read();
  }

  String? _nameOf(String address) {
    for (final o in _snapshot.outputs) {
      if (o.address == address) return o.name;
    }
    return null;
  }

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    await _save((p) => p.setBool(_kEnabled, v));
    _changesCtrl.add(null);
  }

  Future<void> _save(Future<bool> Function(SharedPreferences) write) async {
    try {
      final p = _prefs ??= await _open();
      await write(p);
    } on Object catch (e, st) {
      AppLog.w('speaker prefs not saved', e, st);
    }
  }
}
