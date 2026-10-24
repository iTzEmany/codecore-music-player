// Characterization (38.5, updated in 41.2): the «ask for a name» dialog used to
// exist as three implementations (F-06). The playlist and tag ones are now
// promptName (prompt_name_test.dart); the radio rename went from the raw,
// unlimited text to the shared, stricter rules, pinned here.
import 'package:codecore/data/repositories/radio_repository.dart';
import 'package:codecore/providers/radio_providers.dart';
import 'package:codecore/services/radio/radio_station.dart';
import 'package:codecore/ui/screens/radio/radio_station_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

class _RecordingRadio extends RadioRepository {
  _RecordingRadio(super.db);
  final renamed = <String>[];
  @override
  Future<void> rename(String id, String name) async => renamed.add(name);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump(const Duration(milliseconds: 400));
}

TextField _field(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

void main() {
  group('radio rename (private dialog of the station sheet)', () {
    // The repository is recorded to see what the dialog sends.
    Future<(Harness, _RecordingRadio)> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await Harness.create(tester);
      final repo = _RecordingRadio(h.db);
      const station = RadioStation(
        id: 'r1',
        name: 'Radio Uno',
        streamUrl: 'https://x/s',
      );
      await tester.runAsync(() => repo.save(station));
      await h.pump(
        tester,
        const Scaffold(body: RadioStationSheet(station: station)),
        extraOverrides: [radioRepositoryProvider.overrideWithValue(repo)],
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Rinomina'));
      await tester.pump(const Duration(milliseconds: 400));
      return (h, repo);
    }

    testWidgets('the trimmed name reaches rename; the field is capped at 60', (
      tester,
    ) async {
      final (h, repo) = await open(tester);
      expect(_field(tester).maxLength, 60);
      await _type(tester, '  x  ');
      await _tap(tester, 'Salva');
      expect(repo.renamed, ['x']);
      await h.dispose(tester);
    });
  });
}
