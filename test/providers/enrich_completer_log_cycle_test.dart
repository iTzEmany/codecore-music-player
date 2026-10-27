import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/enrich_completer_providers.dart';
import 'package:codecore/providers/online_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/startup_providers.dart';
import 'package:codecore/providers/user_activity_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/enrich_fakes.dart';

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => AppSettings(autoLyrics: true);
}

void main() {
  test('the line of the round reaches the Registro with the real activity list', () async {
    final r = EnrichRig();
    addTearDown(r.dispose);
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(r.db),
        enrichmentServiceProvider.overrideWithValue(r.svc),
        creditsRepositoryProvider.overrideWithValue(r.credits),
        settingsProvider.overrideWith(_Settings.new),
        userActivityProvider.overrideWithValue(UserActivity()),
        startupSettledProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(c.dispose);
    await r.add(path: '/a.mp3');
    // The start provider wires the Registro; the run itself never reads it.
    c.read(enrichCompleterStartProvider);
    await c.read(enrichCompleterProvider.notifier).runNow();
    final rows = await r.db.select(r.db.activityLogRows).get();
    expect(rows.single.kind, 'enrichBackground');
  });
}
