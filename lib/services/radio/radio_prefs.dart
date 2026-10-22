import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_log.dart';

/// Two small facts the Radio page remembers: whether the mobile-data notice
/// was shown, and when the saved stations were last read again. Kept apart
/// from the settings: they are not choices of the user.
class RadioPrefs {
  static const _noticeKey = 'radioDataNoticeSeen';
  static const _refreshKey = 'radioRefreshedAt';

  Future<SharedPreferences?> _open() async {
    try {
      return await SharedPreferences.getInstance();
    } on Object catch (e, st) {
      AppLog.w('radio prefs unavailable', e, st);
      return null;
    }
  }

  Future<bool> dataNoticeSeen() async => (await _open())?.getBool(_noticeKey) ?? false;

  Future<void> setDataNoticeSeen() async => (await _open())?.setBool(_noticeKey, true);

  /// Milliseconds since epoch of the last refresh, or null.
  Future<int?> refreshedAt() async => (await _open())?.getInt(_refreshKey);

  Future<void> setRefreshedAt(int ms) async => (await _open())?.setInt(_refreshKey, ms);
}
