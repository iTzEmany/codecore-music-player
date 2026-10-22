import 'package:codecore/services/radio/icy_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a publisher format with ~ keeps the first two fields', () {
    expect(
      cleanIcyTitle('HUGEL & DAVID GUETTA ft. X~SHINE~Twenty One~2026~', 'Radio 105'),
      'HUGEL & DAVID GUETTA ft. X · SHINE',
    );
    expect(cleanIcyTitle("Don't Let Me Down~The Beatles~~1969~", 'Virgin'),
        "Don't Let Me Down · The Beatles");
  });

  test('empty or equal to the station name is nothing', () {
    expect(cleanIcyTitle('', 'R101'), isNull);
    expect(cleanIcyTitle(null, 'R101'), isNull);
    expect(cleanIcyTitle('  radio maria ', 'Radio Maria'), isNull);
    expect(cleanIcyTitle('~~', 'R101'), isNull);
  });

  test('«Artist - Title» stays as it is', () {
    expect(cleanIcyTitle(' Queen - Radio Ga Ga ', 'Radio 105'), 'Queen - Radio Ga Ga');
  });
}
