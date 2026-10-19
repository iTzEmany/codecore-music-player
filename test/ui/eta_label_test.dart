import 'package:codecore/l10n/app_localizations_en.dart';
import 'package:codecore/l10n/app_localizations_it.dart';
import 'package:codecore/ui/widgets/format_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ETA wording in minutes, hours and under a minute', () {
    final it = AppLocalizationsIt();
    expect(etaLabel(it, const Duration(seconds: 20)), 'meno di 1 min');
    expect(etaLabel(it, const Duration(minutes: 18)), 'circa 18 min');
    expect(etaLabel(it, const Duration(minutes: 130)), 'circa 2 h 10 min');
    expect(etaLabel(AppLocalizationsEn(), const Duration(minutes: 5)), 'about 5 min');
  });
}
