import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

class _Settings extends SettingsNotifier {
  _Settings(this.spin);
  final bool spin;
  @override
  AppSettings build() => AppSettings(spinCover: spin);

  // No store in these tests: just change the state.
  @override
  void update(AppSettings Function(AppSettings) change) => state = change(state);
}

/// Overrides for the cover spin, which reads «Copertina che ruota».
List<Override> spinOverrides({bool spinCover = true, bool playing = true, Stream<bool>? stream}) => [
      isPlayingProvider.overrideWith((_) => stream ?? Stream.value(playing)),
      settingsProvider.overrideWith(() => _Settings(spinCover)),
    ];
