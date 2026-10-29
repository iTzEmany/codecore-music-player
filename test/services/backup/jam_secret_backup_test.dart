import 'package:codecore/data/settings/jam_secret_store.dart';
import 'package:codecore/services/backup/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('settings.json never carries the Jam block lists', () async {
    SharedPreferences.setMockInitialValues({
      'theme': 'dark',
      jamBlockedKey: '[]',
      jamSuspendedKey: '[]',
    });
    final json = settingsToJson(await SharedPreferences.getInstance());
    expect(json.keys, ['theme']);
  });
}
