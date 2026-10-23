import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/ui/screens/home/cover_fan.dart';
import 'package:codecore/ui/theme/app_theme.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fan card without a cover shows the album title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildThemeFromColors(CcColors.notte, false),
          home: const Scaffold(
            body: CoverFan(
              albums: [
                AlbumSummary(
                  albumKey: 'k',
                  title: 'Titolo senza copertina',
                  artist: 'A',
                  variousArtists: false,
                  trackCount: 1,
                  durationMs: 1000,
                  year: null,
                  coverKey: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Titolo senza copertina'), findsOneWidget);
  });
}
