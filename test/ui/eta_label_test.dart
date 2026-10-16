import 'package:codecore/l10n/app_localizations_en.dart';
import 'package:codecore/l10n/app_localizations_it.dart';
import 'package:codecore/providers/activity_providers.dart';
import 'package:codecore/providers/import_providers.dart';
import 'package:codecore/providers/library_providers.dart' show ScanState;
import 'package:codecore/providers/online_providers.dart' show EnrichJobState;
import 'package:codecore/ui/widgets/format_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ETA wording in minutes, hours and under a minute', () {
    final it = AppLocalizationsIt();
    expect(etaLabel(it, const Duration(seconds: 20)), 'meno di 1 min');
    expect(etaLabel(it, const Duration(minutes: 18)), 'circa 18 min');
    expect(etaLabel(it, const Duration(minutes: 130)), 'circa 2 h 10 min');
    expect(etaLabel(AppLocalizationsEn(), const Duration(minutes: 5)), 'about 5 min');
  });

  test('the Activity centre carries the import estimate', () {
    const imp = ImportProgress(
        id: 1,
        playlistId: 1,
        name: 'Mood',
        total: 120,
        done: 42,
        review: 0,
        missing: 0,
        paused: false,
        eta: Duration(minutes: 18));
    final s = buildActivity(
      scan: const ScanState(),
      enrich: const EnrichJobState(),
      downloads: const [],
      outgoing: const [],
      imports: const [imp],
    );
    expect(s.running.single.eta, const Duration(minutes: 18));
  });
}
