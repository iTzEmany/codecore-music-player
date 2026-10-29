import 'package:shared_preferences/shared_preferences.dart';

const jamBlockedKey = 'jamBlocked';
const jamSuspendedKey = 'jamSuspended';

/// Minimal key-value store for the Jam secrets. Backed by the async
/// shared_preferences API (a separate file from the one the backup exports,
/// and excluded from the Android backup).
abstract class JamSecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class PrefsJamSecretStore implements JamSecretStore {
  final _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
}

class MemoryJamSecretStore implements JamSecretStore {
  MemoryJamSecretStore([Map<String, String>? data]) : data = data ?? {};
  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;
}
