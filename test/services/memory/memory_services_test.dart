import 'dart:io';

import 'package:codecore/services/memory/app_data.dart';
import 'package:codecore/services/memory/dir_size.dart';
import 'package:codecore/services/memory/disk_space.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  File put(String rel, int bytes) {
    final f = File(p.join(root.path, rel))..createSync(recursive: true);
    f.writeAsBytesSync(List.filled(bytes, 1));
    return f;
  }

  setUp(() => root = Directory.systemTemp.createTempSync('memory_test'));
  tearDown(() => root.deleteSync(recursive: true));

  test('directory size adds nested files, can filter by name, and a missing folder is empty', () async {
    put('a/one.bin', 10);
    put('a/b/two_t.png', 5);
    put('three.bin', 1);
    expect(await directorySize(root.path), 16);
    expect(await directorySize(root.path, namePattern: r'_t\.png$'), 5);
    expect(await directorySize(p.join(root.path, 'nope')), 0);
  });

  test('df output is parsed; garbage is not', () {
    final d = parseDf('1B-blocks      Avail\n500107862016 200000000000\n');
    expect(d?.totalBytes, 500107862016);
    expect(d?.freeBytes, 200000000000);
    expect(d?.usedBytes, 300107862016);
    expect(parseDf('error'), isNull);
    expect(parseDf('a b\nx y'), isNull);
  });

  test('clearing the caches removes cache files only', () async {
    final jam = put('support/jam_cache/1.mp3', 100);
    final cover = put('support/covers/abc.jpg', 50);
    final db = put('docs/codecore.sqlite', 40);
    final backup = put('support/tag_backups/x.bak', 30);
    final bg = put('support/theme/bg-t1-1.png', 20);
    final blur = put('support/theme/bg-t1-1-blur20.png', 10);
    final search = put('support/search_cache.json', 8);
    final catalog = put('support/catalog_cache.json', 12);
    var searchCleared = false, imagesCleared = false;
    final cleaner = CacheCleaner(
      jamDir: Directory(p.join(root.path, 'support/jam_cache')),
      themeDir: Directory(p.join(root.path, 'support/theme')),
      searchCacheFile: search,
      clearSearchCache: () async {
        searchCleared = true;
        search.writeAsStringSync('{}');
      },
      catalogCacheFile: catalog,
      clearCatalogCache: () async => catalog.writeAsStringSync('{}'),
      clearImageMemory: () => imagesCleared = true,
      imageMemoryBytes: () => 7,
      jamActive: () => false,
    );
    final r = await cleaner.clear();
    expect(searchCleared && imagesCleared, isTrue);
    expect(jam.existsSync(), isFalse);
    expect(blur.existsSync(), isFalse);
    for (final keep in [cover, db, backup, bg]) {
      expect(keep.existsSync(), isTrue, reason: keep.path);
    }
    expect(r.freedBytes, 100 + 10 + 6 + 10 + 7);
    expect(r.jamSkipped, isFalse);
    expect(clearableKinds, isNot(contains(AppDataKind.covers)));
    expect(clearableKinds, isNot(contains(AppDataKind.database)));
    expect(clearableKinds, isNot(contains(AppDataKind.tagBackups)));
  });

  test('clearing the caches empties the Shuffle+ files too and counts them', () async {
    final log = put('support/suggestions.json', 30);
    final seeds = put('support/seed_ids.json', 12);
    final cleaner = CacheCleaner(
      jamDir: Directory(p.join(root.path, 'jam_cache')),
      themeDir: Directory(p.join(root.path, 'theme')),
      searchCacheFile: File(p.join(root.path, 'search_cache.json')),
      clearSearchCache: () async {},
      catalogCacheFile: File(p.join(root.path, 'catalog_cache.json')),
      clearCatalogCache: () async {},
      clearImageMemory: () {},
      imageMemoryBytes: () => 0,
      jamActive: () => false,
      suggestionFiles: [log, seeds],
      clearSuggestions: () async {
        log.writeAsStringSync('[]');
        seeds.writeAsStringSync('{}');
      },
    );
    final r = await cleaner.clear();
    expect(r.freedBytes, 30 + 12 - 2 - 2);
    expect(clearableKinds, contains(AppDataKind.suggestions));
  });

  test('the app data list measures the Shuffle+ files', () async {
    final paths = AppDataPaths(
      covers: Directory(p.join(root.path, 'covers')),
      database: File(p.join(root.path, 'db')),
      jam: Directory(p.join(root.path, 'jam')),
      theme: Directory(p.join(root.path, 'theme')),
      tagBackups: Directory(p.join(root.path, 'tb')),
      searchCache: File(p.join(root.path, 's')),
      catalogCache: File(p.join(root.path, 'c')),
      log: File(p.join(root.path, 'l')),
      suggestionFiles: [put('suggestions.json', 5), put('seed_ids.json', 7)],
    );
    final items = await measureAppData(paths, podcastBytes: 0, imageMemoryBytes: 0);
    expect(items.firstWhere((i) => i.kind == AppDataKind.suggestions).bytes, 12);
  });

  test('the Jam cache is left alone while a Jam is running', () async {
    final jam = put('jam_cache/1.mp3', 100);
    final search = put('search_cache.json', 2);
    final cleaner = CacheCleaner(
      jamDir: Directory(p.join(root.path, 'jam_cache')),
      themeDir: Directory(p.join(root.path, 'theme')),
      searchCacheFile: search,
      clearSearchCache: () async {},
      catalogCacheFile: File(p.join(root.path, 'catalog_cache.json')),
      clearCatalogCache: () async {},
      clearImageMemory: () {},
      imageMemoryBytes: () => 0,
      jamActive: () => true,
    );
    final r = await cleaner.clear();
    expect(jam.existsSync(), isTrue);
    expect(r.jamSkipped, isTrue);
  });

  test('clearing the caches also empties the file picker copies', () async {
    final copy = put('cache/file_picker/123/backup.zip', 40);
    final other = put('cache/other/keep.bin', 5);
    final cleaner = CacheCleaner(
      jamDir: Directory(p.join(root.path, 'jam_cache')),
      themeDir: Directory(p.join(root.path, 'theme')),
      searchCacheFile: File(p.join(root.path, 'search_cache.json')),
      clearSearchCache: () async {},
      catalogCacheFile: File(p.join(root.path, 'catalog_cache.json')),
      clearCatalogCache: () async {},
      clearImageMemory: () {},
      imageMemoryBytes: () => 0,
      jamActive: () => false,
      pickerTempDir: Directory(p.join(root.path, 'cache/file_picker')),
    );
    final r = await cleaner.clear();
    expect(copy.existsSync(), isFalse);
    expect(other.existsSync(), isTrue);
    expect(r.freedBytes, 40);
  });

  test('«Svuota cache» empties the radio lists and the searches in memory, never the saved stations',
      () async {
    final list = put('support/radio/country_IT.json', 80);
    final tmp = put('support/radio/country_IT.json.tmp', 5);
    final other = put('support/keep.bin', 3);
    var memoryCleared = false;
    final cleaner = CacheCleaner(
      jamDir: Directory(p.join(root.path, 'jam_cache')),
      themeDir: Directory(p.join(root.path, 'theme')),
      searchCacheFile: File(p.join(root.path, 'search_cache.json')),
      clearSearchCache: () async {},
      catalogCacheFile: File(p.join(root.path, 'catalog_cache.json')),
      clearCatalogCache: () async {},
      clearImageMemory: () {},
      imageMemoryBytes: () => 0,
      jamActive: () => false,
      radioDir: Directory(p.join(root.path, 'support/radio')),
      clearRadioMemory: () => memoryCleared = true,
    );
    final r = await cleaner.clear();
    expect(list.existsSync() || tmp.existsSync(), isFalse);
    expect(other.existsSync(), isTrue);
    expect(memoryCleared, isTrue);
    expect(r.freedBytes, 85);
    expect(clearableKinds, contains(AppDataKind.radio));
  });

  test('the app data list measures the radio folder', () async {
    put('radio/country_IT.json', 40);
    final paths = AppDataPaths(
      covers: Directory(p.join(root.path, 'covers')),
      database: File(p.join(root.path, 'db')),
      jam: Directory(p.join(root.path, 'jam')),
      theme: Directory(p.join(root.path, 'theme')),
      tagBackups: Directory(p.join(root.path, 'tb')),
      searchCache: File(p.join(root.path, 's')),
      catalogCache: File(p.join(root.path, 'c')),
      log: File(p.join(root.path, 'l')),
      radio: Directory(p.join(root.path, 'radio')),
    );
    final items = await measureAppData(paths, podcastBytes: 0, imageMemoryBytes: 0);
    expect(items.firstWhere((i) => i.kind == AppDataKind.radio).bytes, 40);
  });
}
