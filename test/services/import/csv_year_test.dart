import 'package:codecore/services/import/csv_profiles.dart';
import 'package:flutter_test/flutter_test.dart';

String _csv(String date) =>
    'Track URI,Track Name,Artist Name(s),Release Date\n'
    'spotify:track:1,Song,Band,$date\n';

void main() {
  test('Release Date gives the year', () {
    expect(readCsvPlaylist('a.csv', _csv('1971-10-11')).rows.single.year, 1971);
    expect(readCsvPlaylist('a.csv', _csv('1971')).rows.single.year, 1971);
  });

  test('an invalid Release Date gives no year', () {
    for (final bad in ['', 'soon', '0000-01-01', '2999', '71-10-11']) {
      expect(readCsvPlaylist('a.csv', _csv(bad)).rows.single.year, isNull,
          reason: bad);
    }
  });
}
