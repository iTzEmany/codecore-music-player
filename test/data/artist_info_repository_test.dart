import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/artist_info_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ArtistInfoRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ArtistInfoRepository(db);
  });
  tearDown(() => db.close());

  test('what is saved for an artist comes back, and a feat. credit shares it', () async {
    expect(await repo.watch('Queen').first, isNull);
    await repo.save('Queen', body: 'Queen are a band.', source: Uri.parse('https://en.wikipedia.org/wiki/Queen_(band)'), lang: 'en');
    final byName = await repo.watch('queen').first;
    expect(byName!.body, 'Queen are a band.');
    expect(byName.sourceUrl, 'https://en.wikipedia.org/wiki/Queen_(band)');
    final withGuest = await repo.watch('Queen feat. David Bowie').first;
    expect(withGuest?.body, 'Queen are a band.', reason: 'same main artist');
  });

  test('saving again replaces the text; an empty name is ignored', () async {
    await repo.save('Queen', body: 'old', source: Uri.parse('https://x/1'), lang: 'en');
    await repo.save('Queen', body: 'new', source: Uri.parse('https://x/2'), lang: 'it');
    expect((await db.select(db.artistInfos).get()).single.body, 'new');
    await repo.save('', body: 'x', source: Uri.parse('https://x/3'), lang: 'en');
    expect(await db.select(db.artistInfos).get(), hasLength(1));
    expect(await repo.watch('').first, isNull);
  });
}
