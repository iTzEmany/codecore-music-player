import 'dart:ui';

import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/services/online/credit_roles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a known role is translated in every language', () {
    expect(
      creditRoleLabel(lookupAppLocalizations(const Locale('it')), 'drumprogrammer'),
      'Programmazione batteria',
    );
    for (final lang in ['en', 'de', 'es', 'fr', 'pt']) {
      final l = lookupAppLocalizations(Locale(lang));
      expect(creditRoleLabel(l, 'drumprogrammer'), isNotEmpty, reason: lang);
    }
    expect(creditGroup('drumprogrammer'), CreditGroup.production);
  });

  test('an unknown role is shown raw, in the other group', () {
    final l = lookupAppLocalizations(const Locale('it'));
    expect(creditRoleLabel(l, 'drum machine drums'), 'drum machine drums');
    expect(creditGroup('drum machine drums'), CreditGroup.other);
    expect(creditRoleLabel(l, 'main_artist'), 'main artist');
  });
}
