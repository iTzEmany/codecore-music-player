import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/services/audio/audio_backend.dart' show TransitionMode;
import 'package:codecore/ui/screens/settings/transition_settings_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('the section shows the three modes and only a crossfade has options',
      (tester) async {
    final h = await Harness.create(tester);
    AppSettings settings() => ProviderScope.containerOf(
            tester.element(find.byType(TransitionSettingsTiles)))
        .read(settingsProvider);
    await h.pump(tester, const Scaffold(body: SingleChildScrollView(child: TransitionSettingsTiles())));
    expect(find.text('Passaggio tra i brani'), findsOneWidget);
    expect(find.textContaining('stesso formato'), findsOneWidget);
    expect(find.text('Normale'), findsOneWidget);
    expect(find.text('Senza pause'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);

    await tester.tap(find.text('Senza pause'));
    await tester.pumpAndSettle();
    expect(settings().transition, TransitionMode.gapless);
    expect(find.byType(Slider), findsNothing, reason: 'gapless has no options');
    await tester.tap(find.text('Dissolvenza'));
    await tester.pumpAndSettle();

    expect(settings().transition, TransitionMode.crossfade);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Durata della dissolvenza: 6 s'), findsOneWidget);
    expect(find.text('Non sfumare nello stesso album'), findsOneWidget);

    tester.widget<Slider>(find.byType(Slider)).onChanged!(10);
    await tester.pumpAndSettle();
    expect(settings().crossfadeSeconds, 10);
    expect(find.text('Durata della dissolvenza: 10 s'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(settings().crossfadePlainInAlbum, isFalse);
    await h.dispose(tester);
  });
}
