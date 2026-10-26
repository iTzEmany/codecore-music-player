import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/providers/enrich_completer_providers.dart';
import 'package:codecore/ui/screens/settings/enrich_complete_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fake extends EnrichCompleterNotifier {
  final calls = <String>[];

  @override
  EnrichCompleterState build() => const EnrichCompleterState();

  @override
  Future<void> runNow() async {
    calls.add('runNow');
    state = const EnrichCompleterState(
      running: true,
      manual: true,
      complete: 3,
      total: 5,
    );
  }

  @override
  void cancel() {
    calls.add('cancel');
    state = const EnrichCompleterState();
  }
}

void main() {
  testWidgets('«Completa» starts at once, then shows the count and «Interrompi»', (tester) async {
    final fake = _Fake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [enrichCompleterProvider.overrideWith(() => fake)],
        child: const MaterialApp(
          locale: Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: EnrichCompleteTile()),
        ),
      ),
    );
    expect(find.text('Interrompi'), findsNothing);
    await tester.tap(find.text("Completa l'arricchimento"));
    await tester.pump();
    expect(fake.calls, ['runNow']);
    expect(find.text('3 di 5 brani completi'), findsOneWidget);

    await tester.tap(find.text('Interrompi'));
    await tester.pump();
    expect(fake.calls, ['runNow', 'cancel']);
    expect(find.text('Interrompi'), findsNothing);
  });
}
