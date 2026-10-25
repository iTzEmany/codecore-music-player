import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/providers/ytm_catalog_providers.dart';
import 'package:codecore/services/online/artist_link_resolver.dart';
import 'package:codecore/ui/widgets/track_artists_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _pump(WidgetTester tester, List<ArtistName> artists) async {
  final asked = <String>[];
  await tester.pumpWidget(ProviderScope(
    overrides: [
      artistLinkResolverProvider.overrideWithValue(ArtistLinkResolver(
        library: (key) async {
          asked.add(key);
          return null;
        },
        search: (_) async => [],
      )),
    ],
    child: MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => goToArtists(context, ref, artists),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  ));
  return asked;
}

void main() {
  testWidgets('several artists: a sheet with one name each, a tap opens that artist', (tester) async {
    final asked = await _pump(tester, const [ArtistName('Alfa'), ArtistName('Beta')]);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byType(TrackArtistsSheet), findsOneWidget);
    expect(find.text('Alfa'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(find.byType(TrackArtistsSheet), findsNothing);
    expect(asked, ['beta']);
  });

  testWidgets('one artist: opens it at once, no sheet', (tester) async {
    final asked = await _pump(tester, const [ArtistName('Alfa')]);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byType(TrackArtistsSheet), findsNothing);
    expect(asked, ['alfa']);
  });
}
