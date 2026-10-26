import 'dart:convert';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/providers/activity_log_providers.dart';
import 'package:codecore/providers/activity_providers.dart';
import 'package:codecore/ui/screens/activity/activity_log_screen.dart';
import 'package:codecore/ui/screens/activity/enrich_round_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

const _item = ActivityItem(
  kind: ActivityKind.enrichBackground,
  key: 'r',
  name: null,
  done: 2,
  total: 1,
  running: false,
);

void main() {
  testWidgets('two groups with the part; a song deleted meanwhile is left out', (tester) async {
    final h = await Harness.create(tester, tracks: 3);
    await h.pump(
      tester,
      EnrichRoundScreen(
        entry: LogEntry(
          at: DateTime(2026),
          item: _item,
          detail: const {
            'updated': {
              'lyrics': [1, 2],
              'curio': [99], // no such song any more
            },
            'none': {
              'lyrics': [3],
            },
          },
        ),
      ),
    );
    expect(find.text('Aggiornati'), findsOneWidget);
    expect(find.text('Senza risultato'), findsOneWidget);
    expect(find.text('Song 0'), findsOneWidget);
    expect(find.text('Song 1'), findsOneWidget);
    expect(find.text('Song 2'), findsOneWidget);
    expect(find.textContaining('Testo'), findsNWidgets(3));
    expect(find.textContaining('Curiosità'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('the line of a round in the Registro opens its songs', (tester) async {
    final h = await Harness.create(tester, tracks: 3);
    await h.db.into(h.db.activityLogRows).insert(
      ActivityLogRowsCompanion.insert(
        at: DateTime.now().millisecondsSinceEpoch,
        kind: 'enrichBackground',
        name: '',
        done: const Value(2),
        total: const Value(1),
        detail: Value(
          jsonEncode({
            'updated': {'lyrics': [1, 2]},
            'none': {'lyrics': [3]},
          }),
        ),
      ),
    );
    await h.pump(
      tester,
      const ActivityLogScreen(),
      extraOverrides: [activityProvider.overrideWithValue(const ActivityState([], []))],
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Arricchimento: 2 brani completati, 1 senza risultato'),
      findsOneWidget,
    );
    await tester.tap(find.textContaining('Arricchimento:'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Aggiornati'), findsOneWidget);
    expect(find.text('Song 2'), findsOneWidget);
    await h.dispose(tester);
  });
}
