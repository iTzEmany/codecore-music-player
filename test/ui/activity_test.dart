import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/providers/activity_providers.dart';
import 'package:codecore/ui/widgets/activity_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  final busy = ActivityState(const [
    ActivityItem(
        kind: ActivityKind.scan, key: 'scan', name: null, done: 1240, total: 3400, progress: 0.36),
    ActivityItem(
        kind: ActivityKind.download, key: 'dl-1', name: 'Una canzone', progress: 0.5, ref: 1),
    ActivityItem(
        kind: ActivityKind.enrich, key: 'enrich', name: null, done: 2, total: 8, progress: 0.25),
  ], const [
    ActivityItem(
        kind: ActivityKind.download, key: 'dl-2', name: 'Finita', running: false),
  ]);

  Future<Harness> pump(WidgetTester tester, ActivityState state) async {
    final h = await Harness.create(tester);
    await tester.pumpWidget(ProviderScope(
      overrides: [...h.overrides, activityProvider.overrideWithValue(state)],
      child: MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Center(child: ActivityButton())),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    return h;
  }

  testWidgets('hidden while idle', (tester) async {
    final h = await pump(tester, const ActivityState([], []));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('shows the count and opens the sheet with every activity',
      (tester) async {
    final h = await pump(tester, busy);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byType(ActivityButton));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Attività'), findsOneWidget);
    expect(find.text('Scansione · 1240/3400'), findsOneWidget);
    expect(find.text('Download · Una canzone'), findsOneWidget);
    expect(find.text('Arricchimento · 2/8'), findsOneWidget);
    expect(find.text('Completate'), findsOneWidget);
    expect(find.text('Pulisci'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('a paused CSV import shows its progress and a resume button',
      (tester) async {
    final h = await pump(
        tester,
        const ActivityState([
          ActivityItem(
              kind: ActivityKind.import,
              key: 'imp-1',
              name: 'Mood',
              done: 3,
              total: 10,
              progress: 0.3,
              paused: true,
              ref: 1),
        ], []));
    await tester.tap(find.byType(ActivityButton));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Importazione «Mood» · in pausa · 3/10'), findsOneWidget);
    expect(find.byTooltip('Riprendi'), findsOneWidget);
    expect(find.byTooltip('Annulla'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('the duplicate search is a line with progress and a cancel button',
      (tester) async {
    final h = await pump(
        tester,
        const ActivityState([
          ActivityItem(
              kind: ActivityKind.cleanup,
              key: 'cleanup',
              name: null,
              done: 4,
              total: 12,
              progress: 1 / 3),
        ], []));
    await tester.tap(find.byType(ActivityButton));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ricerca duplicati: 4 di 12'), findsOneWidget);
    expect(find.byTooltip('Annulla'), findsOneWidget);
    await h.dispose(tester);
  });
}
