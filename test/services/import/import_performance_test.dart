import 'package:codecore/services/import/exportify_reader.dart';
import 'package:codecore/services/import/track_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('5000-row CSV: parse and match against 20000 tracks stays fast', () async {
    final b = StringBuffer(
        'Track URI,ISRC,Track Name,Album Name,Artist Name(s),Duration (ms)\n');
    for (var i = 0; i < 5000; i++) {
      b.writeln('spotify:track:$i,ISRC$i,"Song number $i - Remastered 2011",'
          '"Album ${i % 300}","Artist ${i % 800};Guest $i",${180000 + i}');
    }
    final sw = Stopwatch()..start();
    final csv = await readExportifyInIsolate('big.csv', b.toString());
    final parsed = sw.elapsedMilliseconds;
    final index = LibraryIndex([
      for (var i = 0; i < 20000; i++)
        LibraryEntryLite(
            id: i,
            title: 'Song number ${i * 4} ',
            artist: 'Artist ${(i * 4) % 800}',
            durationMs: 180000 + i * 4),
    ]);
    var known = 0;
    for (final r in csv.rows) {
      if (index.find(r) != null) known++;
    }
    sw.stop();
    expect(csv.rows, hasLength(5000));
    expect(known, greaterThan(1000));
    expect(sw.elapsedMilliseconds, lessThan(2000),
        reason: 'parse ${parsed}ms, total ${sw.elapsedMilliseconds}ms');
  });
}
