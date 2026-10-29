import 'package:codecore/l10n/app_localizations_it.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jamPeople uses the singular for one participant', () {
    final l = AppLocalizationsIt();
    expect(l.jamPeople(1), 'Jam, 1 persona');
    expect(l.jamPeople(3), 'Jam, 3 persone');
  });
}
