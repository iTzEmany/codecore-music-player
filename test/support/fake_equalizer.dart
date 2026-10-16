import 'dart:async';

import 'package:codecore/services/audio/equalizer.dart';

class FakeEq implements Equalizer {
  FakeEq({Completer<EqBands>? ready})
      : _ready = ready ?? (Completer<EqBands>()..complete(five));
  static const five = EqBands(
      centerHz: [60, 230, 910, 3600, 14000], minDb: -15, maxDb: 15);
  final Completer<EqBands> _ready;
  final enabledCalls = <bool>[];
  final gainCalls = <List<double>>[];

  @override
  Future<EqBands> bands() => _ready.future;
  @override
  Future<void> setEnabled(bool enabled) async => enabledCalls.add(enabled);
  @override
  Future<void> setGains(List<double> gainsDb) async => gainCalls.add(gainsDb);
}
