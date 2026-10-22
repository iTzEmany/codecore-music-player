import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/providers/second_opinion_providers.dart';
import 'package:codecore/services/online/enrichment_service.dart' show EnrichField;
import 'package:codecore/services/online/second_opinion.dart';
import 'package:codecore/ui/screens/library/second_opinion_log_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Job extends SecondOpinionNotifier {
  @override
  SecondOpinionState build() => SecondOpinionState(log: [
        SecondOpinionLine(
            trackId: 2, title: 'Due', artist: null, at: DateTime(2026), kind: SecondOpinionKind.notConfirmed),
        SecondOpinionLine(
            trackId: 1,
            title: 'Uno',
            artist: 'Tizio',
            at: DateTime(2026),
            kind: SecondOpinionKind.confirmed,
            written: {EnrichField.lyrics, EnrichField.genre}),
      ]);
}

void main() {
  testWidgets('shows a confirmed and a not confirmed track', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [secondOpinionJobProvider.overrideWith(_Job.new)],
      child: const MaterialApp(
        locale: Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SecondOpinionLogScreen(),
      ),
    ));
    expect(find.text('Uno'), findsOneWidget);
    expect(find.textContaining('Confermato da YouTube Music: Genere, Testo'), findsOneWidget);
    expect(find.text('Due'), findsOneWidget);
    expect(find.textContaining('Non confermato'), findsOneWidget);
  });
}
