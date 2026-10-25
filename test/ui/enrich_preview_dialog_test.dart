import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/providers/online_providers.dart';
import 'package:codecore/services/online/credits.dart';
import 'package:codecore/services/online/enrichment_service.dart';
import 'package:codecore/ui/screens/enrich_preview_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

class _Service extends Fake implements EnrichmentService {
  _Service(this.credits);
  final CreditsPart? credits;

  @override
  Future<EnrichmentProposal> propose(
    Track t, {
    CancelToken? cancel,
    bool lyrics = true,
    bool curiosity = true,
    bool metadata = true,
    bool needGenre = true,
    bool credits = true,
    bool forceCredits = false,
  }) async => EnrichmentProposal(track: t, credits: this.credits);
}

void main() {
  for (final withCredits in [true, false]) {
    testWidgets('credits section ${withCredits ? 'shown' : 'absent'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await Harness.create(tester, tracks: 1);
      final track = (await tester.runAsync(
        () => h.db.select(h.db.tracks).getSingle(),
      ))!;
      await h.pump(
        tester,
        Builder(
          builder: (c) => TextButton(
            onPressed: () => showEnrichPreview(c, track),
            child: const Text('apri'),
          ),
        ),
        extraOverrides: [
          enrichmentServiceProvider.overrideWithValue(
            _Service(
              withCredits
                  ? CreditsPart(
                      credits: [
                        TrackCredit('Mario Rossi', 'producer', 'deezer'),
                      ],
                    )
                  : null,
            ),
          ),
        ],
      );
      await tester.tap(find.text('apri'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Crediti e dettagli'),
        withCredits ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Mario Rossi'),
        withCredits ? findsOneWidget : findsNothing,
      );
      await h.dispose(tester);
    });
  }
}
