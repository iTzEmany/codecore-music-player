// Architecture rule (D-24): lib/ui talks to the data layer only through
// providers. The list below starts FULL (today's offenders) and shrinks as the
// refactor proceeds; a listed file that no longer uses them must be removed.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _forbidden = RegExp(r'databaseProvider|RepositoryProvider');

const _exceptions = <String>{
  'lib/ui/screens/car/car_playlists_sheet.dart',
  'lib/ui/screens/cleanup/album_merge_dialog.dart',
  'lib/ui/screens/cleanup/hidden_tracks_screen.dart',
  'lib/ui/screens/cleanup/tag_backups_screen.dart',
  'lib/ui/screens/devices/devices_sheet.dart',
  'lib/ui/screens/history/history_screen.dart',
  'lib/ui/screens/home/home_blocks.dart',
  'lib/ui/screens/import/exportify_sync_screen.dart',
  'lib/ui/screens/import/import_flow.dart',
  'lib/ui/screens/jam/jam_screen.dart',
  'lib/ui/screens/library/folders_sheet.dart',
  'lib/ui/screens/library/library_screen.dart',
  'lib/ui/screens/lyrics/lyrics_view.dart',
  'lib/ui/screens/now_playing/now_playing_cards.dart',
  'lib/ui/screens/onboarding/onboarding_pages.dart',
  'lib/ui/screens/playlists/add_tracks_screen.dart',
  'lib/ui/screens/playlists/export_dialog.dart',
  'lib/ui/screens/playlists/playlist_detail_screen.dart',
  'lib/ui/screens/playlists/playlist_dialogs.dart',
  'lib/ui/screens/playlists/playlist_picker.dart',
  'lib/ui/screens/playlists/playlists_screen.dart',
  'lib/ui/screens/podcast/podcast_detail_screen.dart',
  'lib/ui/screens/radio/add_station_dialog.dart',
  'lib/ui/screens/radio/radio_actions.dart',
  'lib/ui/screens/radio/radio_sections.dart',
  'lib/ui/screens/radio/radio_station_sheet.dart',
  'lib/ui/screens/releases/follow_button.dart',
  'lib/ui/screens/releases/followed_artists_screen.dart',
  'lib/ui/screens/releases/release_labels.dart',
  'lib/ui/screens/settings/backup_section.dart',
  'lib/ui/screens/settings/missing_tracks_screen.dart',
  'lib/ui/screens/settings/settings_pages.dart',
  'lib/ui/screens/share/receive_tab.dart',
  'lib/ui/screens/share/send_tab.dart',
  'lib/ui/screens/share/track_picker_screen.dart',
  'lib/ui/screens/smart/smart_playlist_editor.dart',
  'lib/ui/screens/smart/smart_playlist_screen.dart',
  'lib/ui/screens/tags/tags_screen.dart',
  'lib/ui/screens/tags/tags_sheet.dart',
  'lib/ui/shell/desktop_sidebar.dart',
  'lib/ui/widgets/bulk_actions.dart',
  'lib/ui/widgets/favorite_actions.dart',
  'lib/ui/widgets/import_event_listener.dart',
  'lib/ui/widgets/track_actions.dart',
};

Map<String, bool> _usage() {
  final out = <String, bool>{};
  for (final f in Directory('lib/ui').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    out[f.path.replaceAll(r'\', '/')] = _forbidden.hasMatch(
      f.readAsStringSync(),
    );
  }
  return out;
}

void main() {
  final usage = _usage();

  test('no lib/ui file outside the exception list uses databaseProvider or *RepositoryProvider', () {
    final offenders = [
      for (final e in usage.entries)
        if (e.value && !_exceptions.contains(e.key)) e.key,
    ]..sort();
    expect(offenders, isEmpty);
  });

  test('every listed exception still uses them (remove it from the list when it stops)', () {
    final stale = [
      for (final f in _exceptions)
        if (usage[f] != true) f,
    ]..sort();
    expect(stale, isEmpty);
  });
}
