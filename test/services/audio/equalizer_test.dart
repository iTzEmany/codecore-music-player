import 'package:codecore/services/audio/equalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const five = [60.0, 230.0, 910.0, 3600.0, 14000.0]; // a typical Android layout
  const ten = [31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0];

  group('presetGains', () {
    test('flat is zero on every band, whatever the layout', () {
      expect(presetGains(EqPreset.flat, five), everyElement(0));
      expect(presetGains(EqPreset.flat, ten), everyElement(0));
      expect(presetGains(EqPreset.flat, const []), isEmpty);
    });

    test('on the ten reference bands the curves come out as defined', () {
      expect(presetGains(EqPreset.bass, ten), [6, 5, 4, 2, 1, 0, 0, 0, 0, 0]);
      expect(presetGains(EqPreset.treble, ten), [0, 0, 0, 0, 0, 1, 2, 4, 5, 6]);
      expect(presetGains(EqPreset.voice, ten), [-2, -2, -1, 0, 2, 3, 3, 2, 0, -1]);
    });

    test('five real bands: bass lifts the lows, treble the highs', () {
      final bass = presetGains(EqPreset.bass, five);
      expect(bass, hasLength(5));
      expect(bass.first, greaterThan(bass.last));
      expect(bass.first, greaterThan(4));
      expect(bass.last, closeTo(0, 1e-9));
      final treble = presetGains(EqPreset.treble, five);
      expect(treble.last, greaterThan(treble.first));
      expect(treble.last, greaterThan(4));
    });

    test('voice boosts the middle bands and trims the extremes', () {
      final v = presetGains(EqPreset.voice, five);
      expect(v[2], greaterThan(v.first));
      expect(v[2], greaterThan(v.last));
      expect(v.first, lessThan(0));
    });

    test('values between two reference bands are interpolated by log-frequency',
        () {
      // 177 Hz is the geometric middle of 125 and 250: the mean of 4 and 2.
      final g = presetGains(EqPreset.bass, const [177.0])[0];
      expect(g, closeTo(3, 0.05));
    });

    test('limits of the device clamp the result', () {
      final g = presetGains(EqPreset.bass, ten, minDb: -1, maxDb: 3);
      expect(g.every((x) => x >= -1 && x <= 3), isTrue);
      expect(g.first, 3);
      final low = presetGains(EqPreset.voice, ten, minDb: -1, maxDb: 12);
      expect(low.first, -1);
    });

    test('frequencies outside the reference range hold the edge values', () {
      expect(presetGains(EqPreset.bass, const [20.0])[0], 6);
      expect(presetGains(EqPreset.treble, const [20000.0])[0], 6);
    });

    test('custom has no curve of its own', () {
      expect(presetGains(EqPreset.custom, five), everyElement(0));
    });
  });

  group('fitGains', () {
    test('pads, cuts and clamps a saved curve to this device', () {
      expect(fitGains(const [1, 2], 4, -12, 12), [1, 2, 0, 0]);
      expect(fitGains(const [1, 2, 3, 4, 5], 3, -12, 12), [1, 2, 3]);
      expect(fitGains(const [30, -30], 2, -15, 15), [15, -15]);
      expect(fitGains(const [], 3, -12, 12), [0, 0, 0]);
    });
  });
}
