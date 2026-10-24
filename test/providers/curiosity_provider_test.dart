import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/curiosity_provider.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/online_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/services/online/curiosity_finder.dart';
import 'package:codecore/services/online/http_client.dart';
import 'package:codecore/services/online/wikipedia_client.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Finder implements CuriosityFinder {
  _Finder(this.pair);

  final CuriosityPair pair;
  String? askedArtist;

  @override
  Future<CuriosityPair> find(String title, String artist, String lang, {String? isrc, int durationMs = 0, cancel}) async {
    askedArtist = artist;
    return pair;
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

Curiosity _c(String text) => Curiosity(text, Uri.parse('https://it.wikipedia.org/wiki/X'), 'it');

void main() {
  late AppDatabase db;
  late ProviderContainer c;
  late Track track;

  Future<void> setUpWith(CuriosityPair pair, {String? stored}) async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    final id = await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/m/a.mp3',
          title: 'Song',
          artist: const Value('Band'),
          albumKey: 'k',
          durationMs: const Value(1000),
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          hasCover: const Value(false),
          addedAt: 1,
          curiosities: Value(stored),
        ));
    track = await (db.select(db.tracks)..where((t) => t.id.equals(id))).getSingle();
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      curiosityFinderProvider.overrideWithValue(_Finder(pair)),
      settingsStoreProvider.overrideWithValue(SettingsStore(await SharedPreferences.getInstance())),
    ]);
  }

  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<String?> savedSong() async =>
      (await (db.select(db.tracks)..where((t) => t.id.equals(track.id))).getSingle()).curiosities;

  test('song and artist found: both are saved and the outcome is clean', () async {
    await setUpWith(CuriosityPair(song: _c('about the song'), artist: _c('about the band')));
    final out = await c.read(curiosityProvider(track.id).notifier).fetch(track);
    expect(out.limited || out.failed || out.nothing, isFalse);
    expect(await savedSong(), startsWith('about the song\n'));
    expect((await db.select(db.artistInfos).get()).single.body, 'about the band');
    expect(c.read(curiosityProvider(track.id)).value, same(out));
  });

  test('nothing found clears the song; a refused artist is flagged, not saved', () async {
    await setUpWith(const CuriosityPair(artistError: RateLimitedException(429)), stored: 'old\nhttps://x');
    final out = await c.read(curiosityProvider(track.id).notifier).fetch(track);
    expect(out.artistLimited, isTrue);
    expect(out.songLimited, isFalse);
    expect(out.nothing, isTrue);
    expect(await savedSong(), isNull, reason: 'the song part was asked: its old text is replaced');
    expect(await db.select(db.artistInfos).get(), isEmpty);
  });

  test('a song lookup that failed leaves the saved text as it was', () async {
    await setUpWith(CuriosityPair(songError: Exception('boom'), artist: _c('about the band')), stored: 'old\nhttps://x');
    final out = await c.read(curiosityProvider(track.id).notifier).fetch(track);
    expect(out.failed, isTrue);
    expect(await savedSong(), 'old\nhttps://x');
  });
}
