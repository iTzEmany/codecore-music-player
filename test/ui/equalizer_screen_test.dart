import 'dart:async';

import 'package:codecore/providers/equalizer_providers.dart';
import 'package:codecore/services/audio/equalizer.dart';
import 'package:codecore/services/audio/output_route.dart';
import 'package:codecore/ui/screens/settings/equalizer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fake_equalizer.dart';

void main() {
  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(500, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('switch, outputs, presets and one slider per band', (tester) async {
    tall(tester);
    final h = await Harness.create(tester);
    final eq = FakeEq();
    await h.pump(tester, const EqualizerScreen(),
        extraOverrides: [equalizerProvider.overrideWithValue(eq)]);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Equalizzatore'), findsWidgets);
    expect(find.text('Altoparlante'), findsOneWidget);
    expect(find.text('Cuffie'), findsOneWidget);
    for (final p in ['Piatto', 'Bassi', 'Voce', 'Acuti', 'Personalizzato']) {
      expect(find.text(p), findsOneWidget, reason: p);
    }
    expect(find.byType(Slider), findsNWidgets(5));
    expect(find.text('60 Hz'), findsOneWidget);
    expect(find.text('3,6 kHz'), findsOneWidget);
    expect(find.text('14 kHz'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('choosing a preset saves it for the output being edited',
      (tester) async {
    tall(tester);
    final h = await Harness.create(tester);
    await h.pump(tester, const EqualizerScreen(),
        extraOverrides: [equalizerProvider.overrideWithValue(FakeEq())]);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Bassi'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(h.store.readSettings().eqSpeaker.preset, EqPreset.bass);
    expect(h.store.readSettings().eqHeadphones.preset, EqPreset.flat);

    await tester.tap(find.text('Cuffie'));
    await tester.pump();
    await tester.tap(find.text('Acuti'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(h.store.readSettings().eqHeadphones.preset, EqPreset.treble);
    expect(h.store.readSettings().eqSpeaker.preset, EqPreset.bass,
        reason: 'the speaker keeps its curve');
    await h.dispose(tester);
  });

  testWidgets('moving a slider turns the curve into a custom one from the preset',
      (tester) async {
    tall(tester);
    final h = await Harness.create(tester);
    await h.pump(tester, const EqualizerScreen(),
        extraOverrides: [equalizerProvider.overrideWithValue(FakeEq())]);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Bassi'));
    await tester.pump(const Duration(milliseconds: 300));

    // Drag the top band up (the slider is turned a quarter, so right = up).
    await tester.drag(find.byType(Slider).last, const Offset(0, -80));
    await tester.pump(const Duration(milliseconds: 500));
    final p = h.store.readSettings().eqSpeaker;
    expect(p.preset, EqPreset.custom);
    expect(p.custom, hasLength(5));
    expect(p.custom.first, greaterThan(4), reason: 'the other bands keep the bass preset');
    expect(p.custom.last, isNot(closeTo(0, 0.01)), reason: 'the dragged band moved');
    await h.dispose(tester);
  });

  testWidgets('reset goes back to flat', (tester) async {
    tall(tester);
    final h = await Harness.create(tester);
    await h.pump(tester, const EqualizerScreen(),
        extraOverrides: [equalizerProvider.overrideWithValue(FakeEq())]);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Voce'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Reimposta'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(h.store.readSettings().eqSpeaker.preset, EqPreset.flat);
    expect(h.store.readSettings().eqSpeaker.custom, isEmpty);
    await h.dispose(tester);
  });

  testWidgets('the bands are waited for, with a note, until the platform reports',
      (tester) async {
    tall(tester);
    final h = await Harness.create(tester);
    final ready = Completer<EqBands>();
    await h.pump(tester, const EqualizerScreen(), extraOverrides: [
      equalizerProvider.overrideWithValue(FakeEq(ready: ready)),
    ]);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('compaiono quando parte il primo brano'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    ready.complete(FakeEq.five);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(Slider), findsNWidgets(5));
    await h.dispose(tester);
  });

  testWidgets('without an equalizer the screen says so', (tester) async {
    final h = await Harness.create(tester);
    await h.pump(tester, const EqualizerScreen(),
        extraOverrides: [equalizerProvider.overrideWithValue(null)]);
    expect(find.textContaining('non è disponibile'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('it opens on the output in use', (tester) async {
    tall(tester);
    final h = await Harness.create(tester);
    await h.pump(tester, const EqualizerScreen(), extraOverrides: [
      equalizerProvider.overrideWithValue(FakeEq()),
      outputRouteProvider.overrideWith(() => _Headphones()),
    ]);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Bassi'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(h.store.readSettings().eqHeadphones.preset, EqPreset.bass);
    await h.dispose(tester);
  });

  group('output route channel', () {
    test('only the name «headphones» means headphones', () {
      expect(isHeadphonesRoute('headphones'), isTrue);
      expect(isHeadphonesRoute('speaker'), isFalse);
      expect(isHeadphonesRoute(null), isFalse);
      expect(isHeadphonesRoute(42), isFalse);
    });

    testWidgets('the route is read at start and follows pushes from Android',
        (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final seen = <bool>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('codecore/audio'), (call) async => 'headphones');
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('codecore/audio'), null));
      final channel = watchOutputRoute(seen.add);
      await tester.pump(const Duration(milliseconds: 50));
      expect(seen, [true], reason: 'asked once at start');

      // Android pushes a change (headphones unplugged).
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'codecore/audio',
          const StandardMethodCodec().encodeMethodCall(const MethodCall('outputRoute', 'speaker')),
          (_) {});
      expect(seen, [true, false]);
      channel.setMethodCallHandler(null);
    });
  });
}

class _Headphones extends OutputRouteNotifier {
  @override
  OutputRoute build() => OutputRoute.headphones;
}
